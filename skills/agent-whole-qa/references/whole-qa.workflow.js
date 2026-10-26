export const meta = {
  name: 'cc-code-whole-qa',
  description: 'cc-code 全量验收：清点 → 按模块 fan-out → 视觉层 → 汇总（五基础分母）→ 修复回环（≤3 轮）→ 冻结候选基线并出合集板',
  phases: [
    { title: '清点' },
    { title: '验收' },
    { title: '视觉' },
    { title: '汇总' },
    { title: '修复' },
    { title: '收口' },
  ],
}

// 宿主契约：Workflow 把脚本体放进 async 上下文执行，顶层 return 是合法返回值（同官方示例）。
// 因此裸跑 node --check 会报「Illegal return statement」，这不是语法错误；静态自查请先把本行以下
// 整段包进 async function(){} 再 node --check。

// ── 参数（主控在 PREFLIGHT 后传入；脚本无文件系统、取不到时间）──
const cfg = args || {}
const ROOT = cfg.projectRoot || '.cc_code'
const ACTIVE = `${ROOT}/active`
const DATE = cfg.date || 'undated'
const BASE_URL = cfg.baseUrl || ''
const LIMIT = cfg.concurrency || 3
const MAX_ROUNDS = cfg.maxRounds || 3
const QA_TYPE = cfg.qaAgentType || 'qa'
const DEV_TYPE = cfg.devAgentType || 'dev'
const BROWSER = cfg.browserTool || 'playwright'
const DESIGN_SPEC = cfg.designSpec || `${ACTIVE}/design.md`
const BASELINE_DIR = cfg.baselineDir || `${ROOT}/test/visual/baseline`
const VIEWPORTS = Array.isArray(cfg.viewports) && cfg.viewports.length ? cfg.viewports : [390, 1440]
const COLOR_MODES = Array.isArray(cfg.colorModes) && cfg.colorModes.length ? cfg.colorModes : ['light']
// 视觉规则库唯一出处（插件侧；宿主按 $CLAUDE_PLUGIN_ROOT 解析）
const UI_GATES = '$CLAUDE_PLUGIN_ROOT/skills/cc-code/references/ui-gates.md'

const COMMON = `你是 cc-code 工作流里的子角色。项目状态目录：${ROOT}。
角色权限唯一出处：${ACTIVE}/Agent.md §三；项目约定一律读 ${ACTIVE}/project.md，不要假设。
subagent 不能问主人：需要人决策的事写进返回值的 escalate / escalated 字段。`

// ── 视觉层口径（规则唯一出处：ui-gates.md；本脚本只传口径，不复制规则内容）──
const VISUAL_RULE = `视觉层（第四层）口径：
- 尺子 = ${DESIGN_SPEC}（视觉数值）+ ${UI_GATES}（规则号、阈值、允许值、基线纪律）
- 判词只认机器检查：Playwright 测试 / axe / 截图比对 / Lighthouse 命令行
- 视觉模型看图只作 VS 线索 → 合集板；⛔ 不写 VH / VM、⛔ 不阻断、⛔ 不进分母
- 基线目录 = ${BASELINE_DIR}；视口 = ${VIEWPORTS.join(' / ')}；亮暗 = ${COLOR_MODES.join(' / ')}
- V 行 = 一个页面（或全站）× 一个适用组；屏宽与亮暗写证据列，⛔ 不乘成行
- 修复轮次中 ⛔ 冻结 / 更新基线、⛔ 改 ${DESIGN_SPEC}、⛔ 改阈值；只有通过轮的收口 qa 才冻候选基线
- 无基线的新页 / 首轮：VH-09.07 标 UNVERIFIABLE，只列候选，不判回归`

// ── 浏览器单实例复用（规则单一出处：skills/cc-code/references/parallel-lanes.md §九）──
// 工具名以宿主实际可用名为准；BROWSER 只是 project.md 登记的逻辑名。
const BROWSER_RULE = `浏览器协议（全流程单实例复用；浏览器验收照常做）：
唯一实例：本次验收只允许一个浏览器（逻辑名 ${BROWSER}，以宿主实际可用的工具名为准；⛔ 不混用第二套浏览器 MCP）。
- ⛔ 不新开第二个浏览器实例；⛔ 非收口 agent 不关闭整个浏览器
- 每个 qa 开工建自己的 tab，并记住它
- 每次浏览器工具调用前先切回自己的 tab —— 并发兄弟 agent 会改掉「当前页」
- 收工只关自己的 tab，不碰别人的
- 截图 / console / snapshot 显式保存到 project.md §六 登记的浏览器产物目录（不依赖 MCP 默认输出目录）
- 实例失联（被关 / 崩溃）→ 写进 escalate 上报，⛔ 不自行重建第二个实例`

// ── 结构化输出 ──
const INVENTORY_SCHEMA = {
  type: 'object',
  properties: {
    modules: { type: 'array', items: { type: 'string' } },
    pages: { type: 'array', items: { type: 'string' } },
    denominators: {
      type: 'object',
      properties: {
        assertions: { type: 'number' },
        ustates: { type: 'number' },
        elements: { type: 'number' },
        apis: { type: 'number' },
        visual: { type: 'number' },
      },
      required: ['assertions', 'ustates', 'elements', 'apis', 'visual'],
    },
    baselineMissing: { type: 'array', items: { type: 'string' } },
    inventoryPath: { type: 'string' },
    notes: { type: 'string' },
  },
  required: ['modules', 'denominators', 'baselineMissing', 'inventoryPath'],
}

const MODULE_SCHEMA = {
  type: 'object',
  properties: {
    module: { type: 'string' },
    reportPath: { type: 'string' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string' },
          evidence: { type: 'string' },
          repro: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'verdict'],
      },
    },
    skipped: { type: 'array', items: { type: 'string' } },
    escalate: { type: 'array', items: { type: 'string' } },
  },
  required: ['module', 'results'],
}

const VISUAL_SCHEMA = {
  type: 'object',
  properties: {
    scope: { type: 'string' },
    reportPath: { type: 'string' },
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string' },
          rule: { type: 'string' },
          baseline: { type: 'string' },
          evidence: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'verdict'],
      },
    },
    vsClues: { type: 'array', items: { type: 'string' } },
    skipped: { type: 'array', items: { type: 'string' } },
    escalate: { type: 'array', items: { type: 'string' } },
  },
  required: ['scope', 'results'],
}

const REDUCE_SCHEMA = {
  type: 'object',
  properties: {
    total: { type: 'number' },
    failedCount: { type: 'number' },
    failures: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          module: { type: 'string' },
          required: { type: 'string' },
          actual: { type: 'string' },
          repro: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'files'],
      },
    },
    coverage: { type: 'string' },
    visualDenominator: { type: 'number' },
    visualCoverage: { type: 'string' },
    visualComboCoverage: { type: 'string' },
    candidates: { type: 'array', items: { type: 'string' } },
    skipped: { type: 'array', items: { type: 'string' } },
    escalations: { type: 'array', items: { type: 'string' } },
    roundReportPath: { type: 'string' },
  },
  required: ['total', 'failedCount', 'failures'],
}

const FIX_SCHEMA = {
  type: 'object',
  properties: {
    fixed: { type: 'array', items: { type: 'string' } },
    escalated: { type: 'array', items: { type: 'string' } },
    files: { type: 'array', items: { type: 'string' } },
    note: { type: 'string' },
  },
  required: ['fixed', 'files'],
}

const REGRESSION_SCHEMA = {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    outcomes: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string' },
          evidence: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
        },
        required: ['id', 'verdict'],
      },
    },
    gateUpdated: { type: 'boolean' },
  },
  required: ['passed', 'outcomes'],
}

const CLOSE_SCHEMA = {
  type: 'object',
  properties: {
    closed: { type: 'boolean' },
    leftoverTabs: { type: 'number' },
  },
  required: ['closed'],
}

const FINALIZE_SCHEMA = {
  type: 'object',
  properties: {
    frozen: { type: 'boolean' },
    candidates: { type: 'number' },
    boardPath: { type: 'string' },
  },
  required: ['frozen'],
}

// ── 工具：分批（尊重 cc-code 并发上限）、按文件分组（并查集）──
function chunk(list, size) {
  const out = []
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size))
  return out
}

function groupByFiles(failures) {
  const parent = failures.map((_, i) => i)
  const find = (i) => (parent[i] === i ? i : (parent[i] = find(parent[i])))
  const union = (a, b) => { parent[find(a)] = find(b) }
  const owner = {}
  failures.forEach((f, i) => {
    ;(f.files || []).forEach((file) => {
      if (owner[file] !== undefined) union(i, owner[file])
      else owner[file] = i
    })
  })
  const groups = {}
  failures.forEach((f, i) => {
    const root = find(i)
    if (!groups[root]) groups[root] = []
    groups[root].push(f)
  })
  return Object.values(groups)
}

// ── ❶ 清点（单个 qa，落盘即锁死分母）──
phase('清点')
log(`清点开始：${ROOT}`)
const inv = await agent(`${COMMON}
你是本轮的清点执行者（qa 角色）。只清点，不测、不修。
你是本次验收的**浏览器 owner**：开工时先看当前会话是否已有唯一浏览器实例——有就复用，没有就建立这一个；owner 不在中途关闭，实例由收口 agent 统一关闭。
${BROWSER_RULE}
${VISUAL_RULE}
读：${ACTIVE}/prd.md（模块清单 + §1.5 断言主表）、${ACTIVE}/ux.md（§一 形态表与页面清单 + 各页 <页章号>.3 五态矩阵 + <页章号>.4 元素清单；页章号按 §1.2 逐页取）、${ACTIVE}/api.md、${ACTIVE}/project.md（§六 测试基建契约）、${DESIGN_SPEC}、${UI_GATES}。
分母清点六个维度：断言 / 页面五态 U / 可交互元素 E / 接口 / 视觉 V 行 / 视觉组合子行。
- 页面 / 元素 / 接口按来源取并集，差集必报；断言与 U / V 编号原样引用，禁止另起编号
- 元素必须标「断点适用」（全断点 / 仅桌面 / 仅窄屏 / 指定视口）
- 视觉 V 行按 ui-gates §8.2 生成；组件陈列页单列、不进生产页面分母；每行标「基线有无」
- 基线有无以 ${BASELINE_DIR} 实际文件为准；缺哪些逐条列进 baselineMissing
落盘 ${ROOT}/docs/qa/${DATE}-inventory.md，落盘即锁定本轮分母。
返回：modules（模块名数组）、pages（生产页面清单）、denominators（assertions / ustates / elements / apis / visual 五个基础分母）、baselineMissing（基线缺失清单）、inventoryPath、notes。`, {
  label: 'qa:inventory',
  phase: '清点',
  agentType: QA_TYPE,
  schema: INVENTORY_SCHEMA,
})

if (!inv) return await end({ status: 'aborted', reason: '清点未返回结果' })
if (!inv.modules || inv.modules.length === 0) {
  return await end({ status: 'aborted', reason: '清点未得到模块清单', inventoryPath: inv.inventoryPath })
}
const visualDenom = inv.denominators.visual || 0
const visualCombos = visualDenom * VIEWPORTS.length * COLOR_MODES.length
log(`分母锁定：${inv.modules.length} 个模块 / 断言 ${inv.denominators.assertions} / U ${inv.denominators.ustates} / 元素 ${inv.denominators.elements} / 接口 ${inv.denominators.apis} / 视觉 V ${visualDenom}（组合 ${visualCombos}）`)
log(`基线缺失 ${(inv.baselineMissing || []).length} 项；并发上限 ${LIMIT}，最大修复轮次 ${MAX_ROUNDS}`)

// ── ❷ 验收：按模块 fan-out（每批 ≤ 并发上限）──
phase('验收')
const moduleResults = []
for (const batch of chunk(inv.modules, LIMIT)) {
  const part = await parallel(batch.map((m) => () => agent(`${COMMON}
你是本模块的验收执行者（qa 角色）。模块：${m}
只测取证：不改业务代码、不改 prd / ux / api。
${BROWSER_RULE}
读 ${ACTIVE}/prd.md 的本模块小节与 §1.5 断言、${ACTIVE}/ux.md 对应页面（<页章号>.3 U 编号 + <页章号>.4 元素；页章号按 §1.2 页面清单取）、${ACTIVE}/api.md 对应接口、${ACTIVE}/project.md 测试契约。
本轮分母（锁定）：断言 ${inv.denominators.assertions} / U 五态 ${inv.denominators.ustates} / 元素 ${inv.denominators.elements} / 接口 ${inv.denominators.apis}；只完成本模块归属部分。
BASE_URL=${BASE_URL}
必做：逐元素点击 + U 五态判定 + 每接口 5 类断言 + console / 网络错误捕获。
视觉层（第四层）由后续「视觉」阶段单独跑，本模块不重复、也不出 V 段判词。
禁止：抽样跳过唯一元素、编造分母外断言、把 FAIL 说成「大概没问题」。
模块报告落盘 ${ROOT}/docs/qa/${DATE}-module-${m}.md，返回 reportPath。
返回 results[]（id / verdict / evidence / repro / files）、skipped[]、escalate[]。`, {
    label: `qa:${m}`,
    phase: '验收',
    agentType: QA_TYPE,
    schema: MODULE_SCHEMA,
  })))
  moduleResults.push(...part.filter(Boolean))
}

const missingModules = inv.modules.filter((m) => !moduleResults.some((r) => r.module === m))
if (missingModules.length) log(`未返回结果的模块：${missingModules.join('、')}`)

// ── ❷.5 视觉层：全部页面 × 视口 × 亮暗（按页面分批；本题只出 V 段判词）──
phase('视觉')
const visualResults = []
if (visualDenom > 0) {
  const visualPages = Array.isArray(inv.pages) && inv.pages.length ? inv.pages : null
  const visualBatches = visualPages ? chunk(visualPages, LIMIT) : [[]]
  for (const batch of visualBatches) {
    const scopeLabel = batch.length ? batch.join(' / ') : 'inventory 登记的全部页面'
    const r = await agent(`${COMMON}
你是本次的视觉验收执行者（qa 角色）。只测视觉层（第四层），不改业务代码、不改需求、不改设计规格、不改基线。
${BROWSER_RULE}
${VISUAL_RULE}
读：${DESIGN_SPEC}、${UI_GATES}、${ACTIVE}/ux.md §一（形态表、页面清单、断点）与对应页面章、${ACTIVE}/project.md §六（视觉门命令 / 视觉测试位置 / 基线目录 / 视口 / 亮暗 / 性能门限）。
本批页面：${scopeLabel}
覆盖：本批页面 × 视口 [${VIEWPORTS.join(', ')}] × 亮暗 [${COLOR_MODES.join(', ')}] × 交互五态；机器检查写成测试或跑登记的视觉门命令。
出 V 行：页面 × 适用组（组不适用不出行）；屏宽与亮暗写进 evidence，⛔ 不乘成行。
判词：任一 VH 命中 → 该行 FAIL；只有 VM → PASS 并备注次要编号。
VS：只整理「VS 号 + 页面 + 视口 + 亮暗 + 截图 + 一句观察」进 vsClues，⛔ 不写判词。
无基线 / 首轮：VH-09.07 标 UNVERIFIABLE，只列候选。
落盘 ${ROOT}/docs/qa/${DATE}-visual-${batch.length ? batch[0].replace(/[^a-zA-Z0-9_-]/g, '_') : 'all'}.md。
返回 scope、results[]（id=V行号 / verdict / rule / baseline / evidence / files）、vsClues[]、skipped[]、escalate[]。`, {
      label: `qa:visual-${batch.length ? batch[0] : 'all'}`,
      phase: '视觉',
      agentType: QA_TYPE,
      schema: VISUAL_SCHEMA,
    })
    if (r) visualResults.push(r)
  }
} else {
  log('视觉分母为 0（无前端 / 不适用）：跳过视觉阶段，全员放行')
}
const visualSkipped = visualResults.flatMap((r) => r.skipped || [])
const visualVs = visualResults.flatMap((r) => r.vsClues || [])
log(`视觉层完成：${visualResults.reduce((n, r) => n + (r.results || []).length, 0)} 个 V 行结果 / ${visualVs.length} 条 VS 线索`)

// ── ❸ 汇总（单个 qa，唯一写者）──
function reducePrompt(round, results) {
  return `${COMMON}
你是汇总记账者（qa 角色）。把各模块与视觉层的原始结果原样合并，不改判、不补判：
${JSON.stringify(results)}
按断言 ID（A）、U 编号、V 行号分别排序。
本轮只重跑「上轮 FAIL + 回归面」：未在本轮结果里出现的项沿用上轮已 PASS 结果（读上一轮报告），⛔ 不得因此把覆盖率算成 0。
用锁定分母 ${JSON.stringify(inv.denominators)} 算五个基础分母覆盖率：断言 / 五态 / 元素 / 接口 / 视觉 V；
视觉组合子行 = V 行 × ${VIEWPORTS.length} 个视口 × ${COLOR_MODES.length} 个亮暗 = ${visualCombos}，只记组合覆盖，⛔ 不乘进 V 主行。
SKIPPED 逐条列原因（含视觉未测组与基线缺失 ${JSON.stringify(inv.baselineMissing || [])}）。
FAIL 分 Critical / Minor；每条 FAIL 必须带涉及文件；视觉 FAIL 必须带规则号 + 实测 / 允许值 + 证据。
VS 人判线索只进合集板 ${ROOT}/docs/qa/${DATE}-vs-board.md，⛔ 不进 failures、不进分母。
落盘 ${ROOT}/docs/qa/${DATE}-round-${round}.md（格式见 skills/agent-whole-qa/references/report-template.md）。
就地更新 ${ACTIVE}/gates.md（你是唯一写者；禁新开轮次章节）：§二 逐行更新 A / U / V 三段，§六 五基础分母 + 视觉组合子行。
返回 total / failedCount / failures[]（含 files）/ coverage / visualDenominator / visualCoverage / visualComboCoverage / candidates[] / skipped / escalations / roundReportPath。`
}

phase('汇总')
let round = 1
const visualForReduce = visualResults.map((r) => ({ module: `视觉:${r.scope}`, results: r.results, vsClues: r.vsClues }))
let red = await agent(reducePrompt(round, [...moduleResults, ...visualForReduce]), {
  label: `qa:reduce-r${round}`,
  phase: '汇总',
  agentType: QA_TYPE,
  schema: REDUCE_SCHEMA,
})

if (!red) return await end({ status: 'aborted', reason: '汇总未返回结果', inventoryPath: inv.inventoryPath })

const escalations = [
  ...moduleResults.flatMap((r) => r.escalate || []),
  ...visualResults.flatMap((r) => r.escalate || []),
  ...(red.escalations || []),
]
const skipped = [
  ...moduleResults.flatMap((r) => r.skipped || []),
  ...visualSkipped,
  ...(red.skipped || []),
]

// ── 收口：先冻候选基线 + 出合集板，再由 closer 关浏览器；任何终态只关一次 ──
async function finalizeVisual(freeze, summary) {
  try {
    return await agent(`${COMMON}
你是视觉收口执行者（qa 角色）。只做收口：冻结候选基线 + 出合集板；不测、不修、不改业务代码。
${VISUAL_RULE}
读：${ROOT}/docs/qa/${DATE}-round-${round}.md、${ACTIVE}/gates.md 的 V 段、${ACTIVE}/project.md §六（基线目录 / 视口 / 亮暗）、已存在的 ${ROOT}/docs/qa/${DATE}-vs-board.md。
${freeze
  ? `本轮为通过轮：按 ${UI_GATES} §七 把「本轮范围内」的组件陈列页与样板页截图冻结为候选基线，文件名带 -candidate，按「浏览器 + 系统」分文件；⛔ 不冻结范围外页面、⛔ 不改阈值。`
  : `本轮未通过：⛔ 禁止冻结、禁止更新基线、禁止改阈值；只整理合集板。`}
合集板：本轮全部 VS 线索整理成一条一行（VS 号 + 页面 + 视口 + 亮暗 + 截图 + 一句观察），落 ${ROOT}/docs/qa/${DATE}-vs-board.md；⛔ 不下审美结论、⛔ 不进分母。
${summary && summary.roundReportPath ? `本轮报告：${summary.roundReportPath}` : ''}
返回 frozen / candidates（冻结或待冻数量）/ boardPath。`, {
      label: 'qa:finalize',
      phase: '收口',
      agentType: QA_TYPE,
      schema: FINALIZE_SCHEMA,
    })
  } catch (_) {
    // 收口失败不改变验收结论；残留由主控报告
    return null
  }
}

async function closeBrowser() {
  try {
    await agent(`${COMMON}
你是浏览器收口执行者（qa 角色）。只做一件事：关闭本次验收的浏览器会话。不测、不修、不改任何文件。
步骤：① 列出所有 tab，逐个关闭；② 关闭唯一浏览器实例一次（用当前工具关闭浏览器的等价操作）；③ 若实例本来未开，返回 closed=false；④ 发现非本次工作流的浏览器实例只报告，不关闭。
返回 closed / leftoverTabs。`, {
      label: 'qa:browser-close',
      phase: '收口',
      agentType: QA_TYPE,
      schema: CLOSE_SCHEMA,
    })
  } catch (_) {
    // 关闭失败不改变验收结论；残留实例由主控报告
  }
}

async function finish(status, reason, summary) {
  const final = visualDenom > 0 ? await finalizeVisual(status === 'pass', summary) : null
  const result = {
    status,
    reason: reason || undefined,
    rounds: round,
    denominators: inv.denominators,
    coverage: summary ? summary.coverage : undefined,
    visualDenominator: summary && summary.visualDenominator !== undefined ? summary.visualDenominator : visualDenom,
    visualCoverage: summary ? summary.visualCoverage : undefined,
    visualComboCoverage: summary ? summary.visualComboCoverage : undefined,
    visualCombos,
    baselineMissing: inv.baselineMissing || [],
    baselineCandidates: final ? final.candidates : undefined,
    vsBoard: final ? final.boardPath : undefined,
    failedCount: summary ? summary.failedCount : 0,
    failures: summary ? summary.failures : [],
    skipped,
    escalations,
    inventoryPath: inv.inventoryPath,
    lastRoundReport: summary ? summary.roundReportPath : undefined,
    moduleReports: moduleResults.map((r) => r.reportPath).filter(Boolean),
    visualReports: visualResults.map((r) => r.reportPath).filter(Boolean),
  }
  await closeBrowser()
  return result
}

async function end(result) {
  await closeBrowser()
  return result
}

// ── ❹ 修复回环：按文件分组 → 并发修 → 回归门 → 收敛检查 ──
while (red.failedCount > 0) {
  if (round > MAX_ROUNDS) {
    log(`已达最大轮次 ${MAX_ROUNDS}，仍未收敛`)
    return await finish('escalate', `超过最大轮次 ${MAX_ROUNDS}`, red)
  }

  phase('修复')
  const groups = groupByFiles(red.failures)
  log(`第 ${round} 轮修复：${red.failedCount} 项 FAIL，按文件分成 ${groups.length} 组`)

  const fixSets = []
  for (const batch of chunk(groups, LIMIT)) {
    const part = await parallel(batch.map((g) => () => agent(`${COMMON}
你是修复执行者（dev 角色）。只修代码，不改需求，也不改尺子。
读 ${ACTIVE}/prd.md / ux.md / api.md / project.md / data.md / ${DESIGN_SPEC}（全部只读；${DESIGN_SPEC} 只用来对齐实现）。
本轮待修 FAIL（原样）：
${JSON.stringify(g)}
禁止：修改 prd / ux / api / ${DESIGN_SPEC} 任何一行；修改或删除测试让它变绿；改 ${ROOT}/test/visual/** 与 ${BASELINE_DIR}；改阈值；顺手重构无关代码。
视觉项要改的是设计数值 / 家族 / 视口契约 → 写进 escalated（dev 无权改尺子，交人走 plan-uiux 或改契约）。
修不动 → 写进 escalated，说明卡点与需要的决策。
修完按 ${ACTIVE}/project.md §六 跑自检（代码规范 / 类型 / 单测，有哪些跑哪些）。
返回 fixed[] / escalated[] / files[]（本次改动文件清单，逐个列全）。`, {
      label: `dev:fix-r${round}-${g[0].id}`,
      phase: '修复',
      agentType: DEV_TYPE,
      schema: FIX_SCHEMA,
    })))
    fixSets.push(...part.filter(Boolean))
  }

  escalations.push(...fixSets.flatMap((f) => f.escalated || []))
  const changedFiles = [...new Set(fixSets.flatMap((f) => f.files || []))]
  if (changedFiles.length === 0) {
    return await finish('escalate', '修复轮没有任何文件改动', red)
  }

  const reg = await agent(`${COMMON}
你是回归执行者（qa 角色）。只重跑「本轮 FAIL 项 + affected 算出的影响面」，不重写全量。
${BROWSER_RULE}
${VISUAL_RULE}
本轮 FAIL：${JSON.stringify(red.failures)}
本轮改动文件：${JSON.stringify(changedFiles)}
先按 ${ACTIVE}/project.md §六 的测试契约算 affected（未装 codegraph 则全量，并在证据里注明来源）。
视觉项加跑基线对比：只比 ${BASELINE_DIR}，按登记容差判；超出即判回归、进本轮 outcomes（⛔ 不改基线迁就）。
本轮是失败轮：⛔ 禁止冻结 / 更新基线、⛔ 改 ${DESIGN_SPEC}、⛔ 改阈值。
PASS 项就地更新 ${ACTIVE}/gates.md 对应行（唯一写者）。
返回 passed / outcomes[] / gateUpdated。`, {
    label: `qa:regression-r${round}`,
    phase: '修复',
    agentType: QA_TYPE,
    schema: REGRESSION_SCHEMA,
  })

  if (!reg) return await finish('escalate', '回归未返回结果', red)
  if (reg.passed) {
    log(`第 ${round} 轮回归全 PASS`)
    return await finish('pass', undefined, red)
  }

  // 收敛门控：FAIL 数必须严格递减，且不得出现新增 FAIL
  const prevCount = red.failedCount
  const prevIds = red.failures.map((f) => f.id)
  round++
  const next = await agent(reducePrompt(round, [{ module: '回归', results: reg.outcomes }]), {
    label: `qa:reduce-r${round}`,
    phase: '汇总',
    agentType: QA_TYPE,
    schema: REDUCE_SCHEMA,
  })
  if (!next) return await finish('escalate', '汇总未返回结果', red)

  const newIds = next.failures.map((f) => f.id).filter((id) => !prevIds.includes(id))
  if (newIds.length) {
    return await finish('escalate', `出现新增 FAIL（震荡）：${newIds.join(', ')}`, next)
  }
  if (next.failedCount >= prevCount) {
    return await finish('escalate', `未收敛：第 ${round} 轮 FAIL 数未递减（${prevCount} → ${next.failedCount}）`, next)
  }
  red = next
}

return await finish('pass', undefined, red)