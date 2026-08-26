// dashboard/server.js — 只读镜子 + 串行派活控制台
// 铁律: GET 只读; POST /dispatch 派活(串行); fs.watch → SSE 推送; 零 npm 依赖
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const { parseAll } = require('./parse');
const { Dispatcher } = require('./dispatch');

const HOST = '127.0.0.1';
const PORTS = [37800, 37801, 37802, 37803, 37804];

function start(projectRoot) {
  const ccDir = path.join(projectRoot, '.cc_code');
  const pubDir = path.join(__dirname, 'public');
  const dispatcher = new Dispatcher(projectRoot, ccDir);

  let snapshot = parseAll(ccDir);
  let lastMtimes = {};
  let debounce = null;

  function refresh() {
    snapshot = parseAll(ccDir);
  }

  // fs.watch active/ → 防抖重解析 → SSE 推送
  const activeDir = path.join(ccDir, 'active');
  try {
    fs.watch(activeDir, { recursive: true }, () => {
      if (debounce) clearTimeout(debounce);
      debounce = setTimeout(() => {
        refresh();
        broadcast({ type: 'snapshot', snapshot });
      }, 300);
    });
  } catch (e) { /* 目录可能不存在, 静默 */ }

  const sseClients = new Set();
  function broadcast(evt) {
    const data = `data: ${JSON.stringify(evt)}\n\n`;
    for (const res of sseClients) { try { res.write(data); } catch {} }
  }

  // dispatcher 事件 → SSE
  dispatcher.on((evt) => broadcast({ ...evt, source: 'dispatch' }));

  const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${HOST}:0`);

    if (req.method === 'GET' && url.pathname === '/') {
      return serveFile(res, path.join(pubDir, 'index.html'), 'text/html; charset=utf-8');
    }
    if (req.method === 'GET' && url.pathname === '/api/snapshot') {
      refresh();
      return json(res, snapshot);
    }
    if (req.method === 'GET' && url.pathname === '/api/dispatch') {
      return json(res, dispatcher.state());
    }
    if (req.method === 'GET' && url.pathname === '/api/file') {
      const rel = (url.searchParams.get('p') || '').replace(/\.\./g, '');
      const full = path.join(ccDir, rel);
      if (!full.startsWith(ccDir)) return json(res, { error: '越界' }, 403);
      try { return plain(res, fs.readFileSync(full, 'utf8')); }
      catch { return json(res, { error: '不可读' }, 404); }
    }
    if (req.method === 'GET' && url.pathname === '/events') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });
      res.write(`data: ${JSON.stringify({ type: 'snapshot', snapshot })}\n\n`);
      sseClients.add(res);
      req.on('close', () => sseClients.delete(res));
      return;
    }
    if (req.method === 'POST' && url.pathname === '/api/dispatch') {
      let body = '';
      req.on('data', (c) => body += c);
      req.on('end', () => {
        try {
          const { task, to } = JSON.parse(body);
          if (!task || !to) return json(res, { error: '缺 task/to' }, 400);
          dispatcher.enqueue(task, to);
          return json(res, { ok: true, queue: dispatcher.queue.length });
        } catch (e) { return json(res, { error: String(e) }, 400); }
      });
      return;
    }
    if (req.method === 'POST' && url.pathname === '/api/dispatch/stop') {
      dispatcher.stop();
      return json(res, { ok: true });
    }
    if (req.method === 'POST' && url.pathname === '/api/dispatch/clear') {
      dispatcher.clearQueue();
      return json(res, { ok: true });
    }
    json(res, { error: 'not found' }, 404);
  });

  let portIdx = 0;

  function tryListen() {
    server.once('error', (e) => {
      if (e.code === 'EADDRINUSE' && portIdx < PORTS.length - 1) {
        portIdx += 1;
        tryListen(); // 冲突自增找空端口
      } else {
        console.log(`[cc-code dashboard] 启动失败: ${e.message}`);
        process.exit(1);
      }
    });
    server.listen(PORTS[portIdx], HOST, () => {
      console.log(`[cc-code dashboard] http://${HOST}:${PORTS[portIdx]}`);
    });
  }
  tryListen();
  return server;
}

function serveFile(res, p, ct) {
  try { res.writeHead(200, { 'Content-Type': ct }); res.end(fs.readFileSync(p)); }
  catch { res.writeHead(404); res.end('not found'); }
}
function json(res, obj, code = 200) { res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' }); res.end(JSON.stringify(obj)); }
function plain(res, t) { res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' }); res.end(t); }

module.exports = { start };

if (require.main === module) {
  const root = process.argv[2] || process.cwd();
  start(root);
}
