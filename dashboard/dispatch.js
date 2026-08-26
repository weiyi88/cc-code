// dashboard/dispatch.js — 串行派活器: 起 claude -p, 流式收输出, FIFO 队列
// 铁律: 一次只跑一个 agent (串行); 队列只排不抢; 卡片落位永远由文件决定
'use strict';
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ALLOWED_TOOLS = 'Read Write Edit Grep Glob Bash(npm test*) Bash(npx vitest*) Bash(npx jest*) Bash(npx tsx*)';

class Dispatcher {
  constructor(projectRoot, ccDir) {
    this.projectRoot = projectRoot;
    this.ccDir = ccDir;
    this.runtimeDir = path.join(ccDir, '.runtime');
    this.queue = [];        // [{task, to}]
    this.current = null;    // {task, to, proc, startTime, sessionId, chunks:[]}
    this.sessionId = this.loadSession();
    this.sessionUsed = false; // 首次用 --session-id, 之后用 --resume
    this.listeners = new Set();
    this.claudeBin = this.findClaude();
  }

  findClaude() {
    try {
      const { execSync } = require('child_process');
      const p = execSync('which claude 2>/dev/null', { encoding: 'utf8' }).trim();
      return p || 'claude';
    } catch { return 'claude'; }
  }

  loadSession() {
    try {
      const p = path.join(this.runtimeDir, 'session');
      if (fs.existsSync(p)) return fs.readFileSync(p, 'utf8').trim();
    } catch {}
    const sid = crypto.randomUUID();
    try {
      fs.mkdirSync(this.runtimeDir, { recursive: true });
      fs.writeFileSync(path.join(this.runtimeDir, 'session'), sid);
    } catch {}
    return sid;
  }

  on(fn) { this.listeners.add(fn); return () => this.listeners.delete(fn); }
  emit(evt) { for (const fn of this.listeners) { try { fn(evt); } catch {} } }

  enqueue(task, to) {
    this.queue.push({ task, to });
    this.emit({ type: 'queue', queue: this.queue.length, task });
    this.pump();
  }

  stop() {
    if (this.current && this.current.proc) {
      try { this.current.proc.kill('SIGTERM'); } catch {}
      this.emit({ type: 'stopped', task: this.current.task });
    }
  }

  clearQueue() {
    const n = this.queue.length;
    this.queue = [];
    this.emit({ type: 'queue_cleared', n });
  }

  // 拖动方向 → agent + prompt
  // ⭐ 唯一合法拖拽: 要修(fix) → 待做(todo), 语义 = 派 Dev 修复
  buildPrompt(task, to) {
    const id = task.id, text = task.text || '';
    if (to === 'todo' || to === 'doing') {
      return {
        agent: 'dev',
        prompt: `执行 cc-code Dev 任务。先 Read .cc_code/active/Agent.md 与 .cc_code/active/status.md 同步坐标与权限, 再按 .cc_code/active/prd.md 的断言 ${id} 实现或修复: ${text}。对照 .cc_code/active/api.md 与 .cc_code/active/data.md 契约, 照 .cc_code/active/ux.md 还原界面。完成后更新 .cc_code/active/status.md 的当前坐标与里程碑。⛔ 不得修改 prd.md / ux.md / gates.md; 修不动就上报, 绝不改需求迁就实现。`,
      };
    }
    if (to === 'verify') {
      // 保留送验入口(供后续交互扩展), 当前 UI 未开放
      return {
        agent: 'qa',
        prompt: `执行 cc-code QA 复验。Read .cc_code/active/prd.md 断言 ${id} (${text}) 作为唯一尺子, 照 .cc_code/active/ux.md 五态, 写测试取证 (不靠读代码发议论)。更新 .cc_code/active/gates.md §二矩阵该行 Verdict 与轮次。⛔ 不得修改 prd.md / ux.md; 永不把 FAIL 四舍五入成 PASS。`,
      };
    }
    return null;
  }

  pump() {
    if (this.current || this.queue.length === 0) return;
    if (!this.claudeBin) {
      this.emit({ type: 'error', msg: 'claude CLI 未找到, 无法派活' });
      this.queue = [];
      return;
    }
    const { task, to } = this.queue.shift();
    const built = this.buildPrompt(task, to);
    if (!built) { this.pump(); return; } // 撤回类, 不起进程

    const args = [
      '-p', built.prompt,
      '--output-format', 'stream-json',
      '--include-partial-messages',
      '--verbose',
      '--model', 'haiku',
      '--agent', built.agent,
      '--add-dir', this.projectRoot,
      '--allowed-tools', ALLOWED_TOOLS,
    ];
    // 首次 --session-id, 之后 --resume (复用上下文)
    if (!this.sessionUsed) { args.push('--session-id', this.sessionId); this.sessionUsed = true; }
    else { args.push('--resume', this.sessionId); }

    const proc = spawn(this.claudeBin, args, { cwd: this.projectRoot });
    const startedAt = Date.now();
    this.current = { task, to, proc, startTime: startedAt, chunks: [], built };
    this.emit({ type: 'start', task, to, agent: built.agent, sessionId: this.sessionId });

    let buf = '';
    proc.stdout.on('data', (d) => {
      buf += d.toString();
      let i;
      while ((i = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, i).trim();
        buf = buf.slice(i + 1);
        if (line) this.handleLine(line);
      }
    });
    proc.stderr.on('data', (d) => {
      const msg = d.toString().trim();
      if (msg) this.emit({ type: 'stderr', msg });
    });
    proc.on('error', (e) => this.emit({ type: 'error', msg: String(e) }));
    proc.on('exit', (code) => {
      this.emit({ type: 'done', task, to, code, durationMs: Date.now() - startedAt });
      this.current = null;
      this.pump();
    });
  }

  // 解析 stream-json 每行, 提炼成精简事件
  handleLine(line) {
    let o;
    try { o = JSON.parse(line); } catch { return; }
    if (o.type === 'stream_event' && o.event) {
      const ev = o.event;
      if (ev.type === 'content_block_delta' && ev.delta) {
        const d = ev.delta;
        if (d.type === 'thinking_delta' && d.thinking) {
          this.emit({ type: 'thinking', text: d.thinking });
        } else if (d.type === 'text_delta' && d.text) {
          this.emit({ type: 'text', text: d.text });
        }
      }
    } else if (o.type === 'assistant' && o.message && o.message.content) {
      for (const c of o.message.content) {
        if (c.type === 'tool_use') {
          this.emit({ type: 'tool', name: c.name, input: c.input });
        }
      }
    } else if (o.type === 'user' && o.message && o.message.content) {
      for (const c of o.message.content) {
        if (c.type === 'tool_result') {
          this.emit({ type: 'tool_result', ok: !c.is_error, tool_use_id: c.tool_use_id, content: (typeof c.content === 'string' ? c.content : '').slice(0, 200) });
        }
      }
    } else if (o.type === 'result') {
      this.emit({ type: 'result', result: o.result, is_error: o.is_error, cost: o.total_cost_usd });
    }
  }

  state() {
    return {
      queue: this.queue.length,
      current: this.current ? {
        task: this.current.task, to: this.current.to, agent: this.current.built.agent,
        elapsedMs: Date.now() - this.current.startTime,
      } : null,
      sessionId: this.sessionId,
      claudeOk: !!this.claudeBin,
    };
  }
}

module.exports = { Dispatcher };
