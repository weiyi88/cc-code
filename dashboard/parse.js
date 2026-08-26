// dashboard/parse.js — .cc_code/active/*.md → JSON 快照
// 铁律: 宽松解析, 永不抛错; 解析失败 → 留空 + errors 记录, 不让页面崩
'use strict';
const fs = require('fs');
const path = require('path');

function readSafe(p) {
  try { return fs.readFileSync(p, 'utf8'); } catch { return null; }
}

// markdown 表格行 → 单元格数组; 分隔行/非表格行返回 null
function rowCells(line) {
  if (!line || !line.trim().startsWith('|')) return null;
  const cells = line.split('|').slice(1, -1).map(c => c.trim());
  if (cells.length && cells.every(c => /^[-:\s]*$/.test(c))) return null; // |---|---|
  return cells;
}

// 取某标题下第一个表格的所有数据行 (跨子标题直到下一个同级 ##)
function firstTable(md, headingRe) {
  if (!md) return [];
  const lines = md.split('\n');
  let inSection = false, started = false, rows = [];
  for (const line of lines) {
    if (headingRe.test(line)) { inSection = true; continue; }
    if (!inSection) continue;
    if (/^##\s/.test(line) && started) break;
    const cells = rowCells(line);
    if (cells) { started = true; rows.push(cells); }
  }
  return rows;
}

function parseStatus(md) {
  if (!md) return {};
  const get = (label) => {
    const m = md.match(new RegExp(`\\*\\*${label}[：:]\\*\\*\\s*(.+)`));
    const v = m ? m[1].trim() : '';
    return v.includes('[待填写]') ? '' : v;
  };
  const listFrom = (heading) => {
    const block = md.match(new RegExp(`##[^\\n]*${heading}[\\s\\S]*?(?=##|$)`));
    const out = [];
    if (block) block[0].split('\n').forEach(l => {
      const m = l.match(/^\s*[*\-]\s+(.+)/) || l.match(/^\s*\d+\.\s+(.+)/);
      if (m && !m[1].includes('[待填写]')) out.push(m[1].trim());
    });
    return out;
  };
  return {
    phase: get('当前执行阶段'),
    role: get('当前激活角色'),
    module: get('当前聚焦模块'),
    issue: get('正在处理的 Issue'),
    nextSteps: listFrom('下一步'),
    blockers: listFrom('卡点'),
    milestones: listFrom('里程碑'),
  };
}

function parseAgent(md) {
  if (!md) return {};
  const g = (label) => {
    const m = md.match(new RegExp(`\\*\\*${label}[：:]\\*\\*\\s*([^\\n]+)`));
    return m ? m[1].trim() : '';
  };
  return { phase: g('当前执行阶段'), role: g('当前激活角色') };
}

// prd.md §1.5 A 断言主表
function parsePrdAssertions(md) {
  const rows = firstTable(md, /1\.5|验收断言/);
  return rows.map(r => ({ id: (r[0]||'').trim(), text: (r[1]||'').trim() }))
    .filter(a => /^A\d+/.test(a.id) && !a.text.includes('[待填写]'));
}

// ux.md §2.3 U 编号五态矩阵
function parseUxAssertions(md) {
  const rows = firstTable(md, /2\.3|交互状态矩阵/);
  return rows.map(r => ({ id: (r[0]||'').trim(), element: (r[1]||'').trim(), state: (r[2]||'').trim() }))
    .filter(a => /^U\d/.test(a.id));
}

function normalizeVerdict(v) {
  const s = (v || '').toUpperCase();
  if (s.includes('PASS') || s.includes('✅')) return 'PASS';
  if (s.includes('FAIL') || s.includes('❌')) return 'FAIL';
  if (s.includes('UNVERIF') || s.includes('⚠️')) return 'UNVERIFIABLE';
  return 'PENDING';
}

// gates.md §二 追溯矩阵 → { A: {id:verdict}, U: {id:verdict} }
function parseGates(md) {
  const out = { A: {}, U: {} };
  if (!md) return out;
  firstTable(md, /2\.1|A\s*段/).forEach(r => {
    if (r[0] && /^A\d+/.test(r[0])) out.A[r[0].trim()] = normalizeVerdict(r[1]);
  });
  firstTable(md, /2\.2|U\s*段/).forEach(r => {
    if (r[0] && /^U\d/.test(r[0])) out.U[r[0].trim()] = normalizeVerdict(r[1]);
  });
  return out;
}

// 四态合成: fix(要修) / todo(待做) / doing(进行中) / done(已过)
function verdictToStatus(v) {
  if (v === 'FAIL') return 'fix';
  if (v === 'PASS') return 'done';
  return 'todo'; // PENDING / UNVERIFIABLE 都算待做(未验)
}

function synthesizeTasks(A, U, gates, issueText) {
  const tasks = [];
  const doingIds = new Set();
  if (issueText) {
    (issueText.match(/[AU]\d+(\.\w+)*/g) || []).forEach(m => doingIds.add(m));
  }
  for (const a of A) {
    const v = gates.A[a.id] || 'PENDING';
    let status = verdictToStatus(v);
    if (doingIds.has(a.id)) status = 'doing';
    tasks.push({ id: a.id, kind: 'A', text: a.text, status, verdict: v });
  }
  for (const u of U) {
    const v = gates.U[u.id] || 'PENDING';
    let status = verdictToStatus(v);
    if (doingIds.has(u.id)) status = 'doing';
    tasks.push({ id: u.id, kind: 'U', text: `${u.element}${u.state ? ' · ' + u.state : ''}`, status, verdict: v });
  }
  return tasks;
}

function parseAll(ccDir) {
  const active = path.join(ccDir, 'active');
  const snap = { ok: true, tasks: [], status: {}, agent: {}, coverage: {}, errors: [], ts: Date.now() };

  const statusMd = readSafe(path.join(active, 'status.md'));
  if (statusMd) snap.status = parseStatus(statusMd); else snap.errors.push('status.md 不可读');

  const agentMd = readSafe(path.join(active, 'Agent.md'));
  if (agentMd) snap.agent = parseAgent(agentMd); else snap.errors.push('Agent.md 不可读');

  const A = parsePrdAssertions(readSafe(path.join(active, 'prd.md')));
  const U = parseUxAssertions(readSafe(path.join(active, 'ux.md')));
  const gates = parseGates(readSafe(path.join(active, 'gates.md')));

  snap.tasks = synthesizeTasks(A, U, gates, snap.status.issue || '');

  const aVals = Object.values(gates.A), uVals = Object.values(gates.U);
  snap.coverage = {
    A: { total: A.length, pass: aVals.filter(v => v === 'PASS').length, fail: aVals.filter(v => v === 'FAIL').length },
    U: { total: U.length, pass: uVals.filter(v => v === 'PASS').length, fail: uVals.filter(v => v === 'FAIL').length },
  };
  snap.coverage.A.todo = snap.coverage.A.total - snap.coverage.A.pass - snap.coverage.A.fail;
  snap.coverage.U.todo = snap.coverage.U.total - snap.coverage.U.pass - snap.coverage.U.fail;
  return snap;
}

module.exports = { parseAll, parseStatus, parseAgent, parsePrdAssertions, parseUxAssertions, parseGates, synthesizeTasks };
