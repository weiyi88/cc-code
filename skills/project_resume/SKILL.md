---
name: project_resume
description: 快速读取当前项目真实技术栈和功能，生成标准化项目介绍文案（纯文本，无 markdown）。当用户说"介绍项目"、"项目文案"、"project resume"、"项目简介"、"写项目介绍"、"project_resume" 时触发。
disable-model-invocation: true
---

# 项目介绍生成指南

## 目标

读取当前项目的真实代码和配置，生成一份标准格式的纯文本项目介绍，不捏造、不假设任何技术栈。

## 步骤

### 第 1 步：读取项目真实信息

按优先级读取以下文件，提取真实的技术栈和功能：

1. `package.json` — 获取所有 dependencies 和 devDependencies
2. `prisma/schema.prisma` — 获取数据模型、数据库类型
3. `CLAUDE.md` 或 `README.md` — 获取项目描述和功能说明
4. `app/` 目录结构 — 了解主要功能模块

同时从项目配置中获取：
- 项目域名/URL（从 NEXTAUTH_URL、vercel 配置、或 CLAUDE.md 中提取）
- 项目真实名称（非 package.json 的技术名，而是产品名）

### 第 2 步：分析提炼

从读取的内容中提炼：

- **项目名**：产品名称，用书名号包裹，如《智能办公文档翻译平台》
- **项目 URL**：真实域名，如 https://translateagent.app
- **简介**：50 字左右，一句话说清楚是什么产品、做什么、核心价值
- **技术栈**：从 package.json dependencies 提取核心技术，用顿号或逗号分隔，写在一行
- **项目亮点**：5-8 条，每条不超过 30 字，精炼突出技术要点

### 第 3 步：严格按以下格式输出

纯文本，无任何 markdown 符号（无 #、无 **、无 ```、无多余空行）：

《项目名》URL

简介（50字左右）

技术栈: 技术1、技术2、技术3、技术4...

1.亮点一，不超过30字，突出技术要点
2. 亮点二，不超过30字，突出技术要点
3. 亮点三，不超过30字，突出技术要点
...

## 格式参考示例

《智能办公文档翻译平台》https://translateagent.app

一款面向企业和个人的 AI 驱动文档翻译 SaaS 平台，支持 PPTX、DOCX、XLSX、PDF 全格式翻译，完整保留原始文档排版与样式，上传即翻译，下载即可用。

技术栈: Next.js、TypeScript、Tailwind CSS、shadcn/ui、NextAuth v5、Prisma、PostgreSQL、Redis、Trigger.dev、pptxgenjs、docx、Zod、Vercel、Supabase

1.格式零损耗翻译，仅替换文本节点，其他内容格式完整保留
2. 多模型动态切换，集成 OpenAI、Claude、DeepSeek，自由选择模型
3. 自定义术语库，内置倒排索引，保障品牌词翻译一致性
4. 异步任务队列，Trigger.dev 调度，支持优先级、进度追踪、自动重试
5. 完整订阅体系，FREE/PRO/ENTERPRISE 三档，对接 Stripe 支付
6. 邮箱 OTP + GitHub OAuth 双通道登录，NextAuth v5 统一认证
7. 使用量精细统计，记录模型、Token、费用、页数，支持成本管控

## 注意事项

- 只写真实存在于项目中的技术，绝对不要捏造
- 技术栈写在一行，用顿号分隔，不分类、不换行
- 亮点每条严格不超过 30 字，要精炼，突出具体技术实现
- 输出全程不含任何 markdown 格式符号
- 简介控制在 50 字左右，不超过 80 字
