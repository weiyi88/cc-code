export const meta = {
  name: 'cc-code-whole-qa',
  description: 'cc-code 全量验收：清点 → 按模块 fan-out → 汇总 → 修复回环（≤3 轮）',
  phases: [
    { title: '清点' },
    { title: '验收' },
    { title: '汇总' },
    { title: '修复' },
  ],
}

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

const COMMON = `你是 cc-code 工作流里的子角色。项目状态目录：${ROOT}。
角色权限唯一出处：${ACTIVE}/Agent.md §三；项目约定一律读 ${ACTIVE}/project.md，不要假设。
subagent 不能问主人：需要人决策的事写进返回值的 escalate / escalated 字段。`

// ── 浏览器单实例复用（规则单一出处：skills/cc-code/references/parallel-lanes.md §九）──
const BROWSER_RULE = `浏览器协议（全流程单实例复用；浏览器验收照常做）：
唯一实例已由主控 PREFLIGHT 打开，工具 ${BROWSER}（取自 ${ACTIVE}/project.md §六「浏览器工具」）。
- ⛔ 不新开浏览器实例、⛔ 不 browser_close（关闭只由主控收口做一次）
- 开工 browser_tabs(new) 建自己的 tab 并记住句柄
- 每次浏览器操作前先 select 自己的 tab —— 并发兄弟 agent 会切走「当前页」
- 收工只关自己的 tab，不碰别人的、也不关整个实例
- 截图 / console / snapshot 落 project.md §六 登记的浏览器产物目录`

// ── 结构化输出 ──
const INVENTORY_SCHEMA = {
  type: 'object',
  properties: {
    modules: { type: 'array', items: { type: 'string' } },
    denominators: {
      type: 'object',
      properties: {
        assertions: { type: 'number' },
        ustates: { type: 'number' },
        elements: { type: 'number' },
        apis: { type: 'number' },
      },
      required: ['assertions', 'ustates', 'elements', 'apis'],
    },
    inventoryPath: { type: 'string' },
    notes: { type: 'string' },
  },
  required: ['modules', 'denominators', 'inventoryPath'],
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
${BROWSER_RULE}
读：${ACTIVE}/prd.md（模块清单 + §1.5 断言主表）、${ACTIVE}/ux.md（§2.3 U 编号矩阵 + §2.4 元素清单）、${ACTIVE}/api.md、${ACTIVE}/project.md（§六 测试基建契约）。
页面 / 元素 / 接口三来源取并集，差集必报；断言与 U 编号原样引用，禁止另起编号。
落盘 ${ROOT}/docs/qa/${DATE}-inventory.md，落盘即锁定本轮分母。
返回：modules（模块名数组）、denominators（四个分母数字）、inventoryPath、notes。`, {
  label: 'qa:inventory',
  phase: '清点',
  agentType: QA_TYPE,
  schema: INVENTORY_SCHEMA,
})

if (!inv) return { status: 'aborted', reason: '清点未返回结果' }
if (!inv.modules || inv.modules.length === 0) {
  return { status: 'aborted', reason: '清点未得到模块清单', inventoryPath: inv.inventoryPath }
}
log(`分母锁定：${inv.modules.length} 个模块 / 断言 ${inv.denominators.assertions} / U ${inv.denominators.ustates} / 元素 ${inv.denominators.elements} / 接口 ${inv.denominators.apis}`)
log(`并发上限 ${LIMIT}，最大修复轮次 ${MAX_ROUNDS}`)

// ── ❷ 验收：按模块 fan-out（每批 ≤ 并发上限）──
phase('验收')
const moduleResults = []
for (const batch of chunk(inv.modules, LIMIT)) {
  const part = await parallel(batch.map((m) => () => agent(`${COMMON}
你是本模块的验收执行者（qa 角色）。模块：${m}
只测取证：不改业务代码、不改 prd / ux / api。
${BROWSER_RULE}
读 ${ACTIVE}/prd.md 的本模块小节与 §1.5 断言、${ACTIVE}/ux.md 对应页面（§2.3 U 编号 + §2.4 元素）、${ACTIVE}/api.md 对应接口、${ACTIVE}/project.md 测试契约。
本轮分母（锁定）：断言 ${inv.denominators.assertions} / U 五态 ${inv.denominators.ustates} / 元素 ${inv.denominators.elements} / 接口 ${inv.denominators.apis}；只完成本模块归属部分。
BASE_URL=${BASE_URL}
必做：逐元素点击 + U 五态判定 + 每接口 5 类断言 + console / 网络错误捕获。
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

// ── ❸ 汇总（单个 qa，唯一写者）──
function reducePrompt(round, results) {
  return `${COMMON}
你是汇总记账者（qa 角色）。把各模块原始结果原样合并，不改判、不补判：
${JSON.stringify(results)}
按断言 ID 与 U 编号排序；用锁定分母 ${JSON.stringify(inv.denominators)} 算四个覆盖率；SKIPPED 逐条列原因；FAIL 分 Critical / Minor；每条 FAIL 必须带涉及文件。
落盘 ${ROOT}/docs/qa/${DATE}-round-${round}.md。
就地更新 ${ACTIVE}/gates.md（你是唯一写者；禁新开轮次章节）。
返回 total / failedCount / failures[]（含 files）/ coverage / skipped / escalations / roundReportPath。`
}

phase('汇总')
let round = 1
let red = await agent(reducePrompt(round, moduleResults), {
  label: `qa:reduce-r${round}`,
  phase: '汇总',
  agentType: QA_TYPE,
  schema: REDUCE_SCHEMA,
})

if (!red) return { status: 'aborted', reason: '汇总未返回结果', inventoryPath: inv.inventoryPath }

const escalations = [
  ...moduleResults.flatMap((r) => r.escalate || []),
  ...(red.escalations || []),
]
const skipped = [
  ...moduleResults.flatMap((r) => r.skipped || []),
  ...(red.skipped || []),
]

function finish(status, reason, summary) {
  return {
    status,
    reason: reason || undefined,
    rounds: round,
    denominators: inv.denominators,
    coverage: summary ? summary.coverage : undefined,
    failedCount: summary ? summary.failedCount : 0,
    failures: summary ? summary.failures : [],
    skipped,
    escalations,
    inventoryPath: inv.inventoryPath,
    lastRoundReport: summary ? summary.roundReportPath : undefined,
    moduleReports: moduleResults.map((r) => r.reportPath).filter(Boolean),
  }
}

// ── ❹ 修复回环：按文件分组 → 并发修 → 回归门 → 收敛检查 ──
while (red.failedCount > 0) {
  if (round > MAX_ROUNDS) {
    log(`已达最大轮次 ${MAX_ROUNDS}，仍未收敛`)
    return finish('escalate', `超过最大轮次 ${MAX_ROUNDS}`, red)
  }

  phase('修复')
  const groups = groupByFiles(red.failures)
  log(`第 ${round} 轮修复：${red.failedCount} 项 FAIL，按文件分成 ${groups.length} 组`)

  const fixSets = []
  for (const batch of chunk(groups, LIMIT)) {
    const part = await parallel(batch.map((g) => () => agent(`${COMMON}
你是修复执行者（dev 角色）。只修代码，不改需求。
读 ${ACTIVE}/prd.md / ux.md / api.md / project.md / data.md（全部只读）。
本轮待修 FAIL（原样）：
${JSON.stringify(g)}
禁止：修改 prd / ux / api 任何一行、修改或删除测试让它变绿、顺手重构无关代码。
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
    return finish('escalate', '修复轮没有任何文件改动', red)
  }

  const reg = await agent(`${COMMON}
你是回归执行者（qa 角色）。只重跑「本轮 FAIL 项 + affected 算出的影响面」，不重写全量。
${BROWSER_RULE}
本轮 FAIL：${JSON.stringify(red.failures)}
本轮改动文件：${JSON.stringify(changedFiles)}
先按 ${ACTIVE}/project.md §六 的测试契约算 affected（未装 codegraph 则全量，并在证据里注明来源）。
PASS 项就地更新 ${ACTIVE}/gates.md 对应行（唯一写者）。
返回 passed / outcomes[] / gateUpdated。`, {
    label: `qa:regression-r${round}`,
    phase: '修复',
    agentType: QA_TYPE,
    schema: REGRESSION_SCHEMA,
  })

  if (!reg) return finish('escalate', '回归未返回结果', red)
  if (reg.passed) {
    log(`第 ${round} 轮回归全 PASS`)
    return finish('pass', undefined, red)
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
  if (!next) return finish('escalate', '汇总未返回结果', red)

  const newIds = next.failures.map((f) => f.id).filter((id) => !prevIds.includes(id))
  if (newIds.length) {
    return finish('escalate', `出现新增 FAIL（震荡）：${newIds.join(', ')}`, next)
  }
  if (next.failedCount >= prevCount) {
    return finish('escalate', `未收敛：第 ${round} 轮 FAIL 数未递减（${prevCount} → ${next.failedCount}）`, next)
  }
  red = next
}

return finish('pass', undefined, red)