---
description: 基于 Supabase Auth 实现通用登录系统，零新依赖。覆盖邮箱密码登录、OAuth(google/github)、邮箱验证码注册、邮箱验证码改密。当用户说"login_auto"、"登录实现"、"Supabase登录"、"通用登录"时触发。
disable-model-invocation: true
---

# Supabase Auth 通用登录系统实现指南

本 skill 是**与项目无关的通用登录逻辑指南**，适用于任意 Next.js + Supabase 项目。不绑定特定 i18n 框架、不绑定特定语言组合、不绑定特定 UI 库。三大场景全覆盖：

- **登录**：邮箱密码 + OAuth (Google/GitHub)
- **注册**：邮箱 + 验证码 + 密码 + 确认密码
- **修改密码**（忘记密码/未登录）：邮箱 + 验证码 + 新密码

---

## 执行流程

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
环境检查   后端实现   前端UI    回调路由   构建验证
```

---

## Phase 0: 环境检查

### 0.1 检查已有 Supabase 配置

```
扫描:
├── package.json → @supabase/supabase-js 存在?
├── package.json → @supabase/ssr 存在?
├── lib/supabase/client.ts 存在?
├── lib/supabase/server.ts 存在?
├── middleware.ts (或 Next.js 16 的 proxy.ts) → 包含 supabase session 刷新?
├── .env.local → NEXT_PUBLIC_SUPABASE_URL + ANON_KEY 存在?
└── app/auth/callback/route.ts 存在?
```

> 若项目使用 i18n，额外检查其 Auth 命名空间是否已含本 skill 所需的错误消息 key（见文末「错误消息键名清单」）。i18n 框架与语言组合由项目自定，本 skill 不强制。

### 0.2 若缺失，先安装依赖

```bash
pnpm add @supabase/supabase-js @supabase/ssr
```

### 0.3 若缺失，先创建基础设施文件

按下面的模板创建缺失文件，已有的跳过。

---

## Phase 1: 后端实现

### 1.1 环境变量

**`.env.example`** 追加:
```
# Supabase Auth
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

**`.env.local`** 填入实际值。

### 1.2 Supabase 客户端

**`lib/supabase/client.ts`** (浏览器端):
```typescript
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

**`lib/supabase/server.ts`** (服务端):
```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server Component 中 setAll 可能失败，忽略
          }
        },
      },
    }
  )
}
```

### 1.3 Middleware (Session 刷新)

**`middleware.ts`** (或 Next.js 16 的 `proxy.ts`) — 在已有 middleware 中追加 Supabase session 刷新逻辑:

```typescript
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 刷新 session (不保护路由，所有页面公开)
  await supabase.auth.getUser()

  return supabaseResponse
}
```

> **注意**: 如果项目有 next-intl 等其他 middleware，Supabase 刷新应放在最后执行。

### 1.4 三大场景 — Supabase API 映射

```
┌──────────────────┬──────────────────────────────────────────────┐
│  功能            │  Supabase Auth API                           │
├──────────────────┼──────────────────────────────────────────────┤
│  ① 邮箱+密码登录 │  supabase.auth.signInWithPassword({          │
│                  │    email, password                           │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ① OAuth 登录    │  supabase.auth.signInWithOAuth({             │
│                  │    provider: 'google' | 'github',            │
│                  │    options: { redirectTo: origin+/auth/callback }│
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ② 注册-发验证码 │  supabase.auth.signInWithOtp({               │
│                  │    email,                                    │
│                  │    options: { shouldCreateUser: true }       │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ② 注册-验证+设密│  1. supabase.auth.verifyOtp({                │
│                  │       email, token, type: 'email'            │
│                  │     })  → 拿到 session                       │
│                  │  2. supabase.auth.updateUser({               │
│                  │       password,                              │
│                  │       data: { nickname }                     │
│                  │     })                                       │
├──────────────────┼──────────────────────────────────────────────┤
│  ③ 改密-发验证码 │  supabase.auth.signInWithOtp({               │
│  (忘记密码)      │    email,                                    │
│                  │    options: { shouldCreateUser: false }      │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ③ 改密-验证+设密│  1. supabase.auth.verifyOtp({                │
│                  │       email, token, type: 'email'            │
│                  │     })  → 拿到 session                       │
│                  │  2. supabase.auth.updateUser({               │
│                  │       password: newPassword                  │
│                  │     })                                       │
├──────────────────┼──────────────────────────────────────────────┤
│  退出登录        │  supabase.auth.signOut()                     │
├──────────────────┼──────────────────────────────────────────────┤
│  监听状态变化    │  supabase.auth.onAuthStateChange(callback)    │
├──────────────────┼──────────────────────────────────────────────┤
│  获取当前用户    │  supabase.auth.getUser()                     │
└──────────────────┴──────────────────────────────────────────────┘
```

> **关键**: 注册与改密都走「signInWithOtp → verifyOtp → updateUser」三步组合，**不使用** `signUp` 和 `resetPasswordForEmail`。区别仅在 `shouldCreateUser`：注册=true，改密=false。

### 1.5 错误映射 (Supabase → 用户友好消息)

```
Supabase error.message              →  消息 key
─────────────────────────────────────────────────────
"Invalid login credentials"          →  invalidCredentials
"Email not confirmed"                →  emailNotConfirmed
"User already registered"            →  emailAlreadyExists
"Password should be at least 6..."   →  passwordTooShort
"New password should be different"   →  passwordSameAsOld
"Token has expired or is invalid"    →  codeExpired
"already been confirmed"             →  codeExpired
"Invalid" (OTP)                      →  codeIncorrect
"rate limit" / "too many" / "429"    →  sendCodeRateLimit
"For security purposes, you can..."  →  passwordRateLimit
其他                                  →  loginFailed / signupFailed / changePasswordFailed
```

### 1.6 前端校验规范 (统一工具函数)

**`lib/auth-validation.ts`**:

```typescript
export const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
export const PASSWORD_MIN_LENGTH = 8

/** 邮箱格式校验 */
export function validateEmail(email: string): boolean {
  return EMAIL_REGEX.test(email.trim())
}

/**
 * 密码校验: 长度≥8 + 必含字母与数字
 * @returns null=通过, 否则返回错误消息 key
 */
export function validatePassword(password: string): string | null {
  if (password.length < PASSWORD_MIN_LENGTH) return 'passwordTooShort'
  const hasLetter = /[a-zA-Z]/.test(password)
  const hasNumber = /[0-9]/.test(password)
  if (!hasLetter || !hasNumber) return 'passwordTooWeak'
  return null
}

/** 二次确认密码一致性 */
export function validateConfirmPassword(password: string, confirm: string): boolean {
  return password.length > 0 && password === confirm
}

/** 验证码格式: 6 位数字 */
export function validateOtp(otp: string): boolean {
  return /^\d{6}$/.test(otp.trim())
}
```

校验规则汇总:

```
┌────────────┬─────────────────────────────────┬──────────────────────┐
│ 校验项     │ 规则                             │ 失败消息 key          │
├────────────┼─────────────────────────────────┼──────────────────────┤
│ 邮箱格式    │ /^[^\s@]+@[^\s@]+\.[^\s@]+$/    │ invalidEmail         │
│ 密码长度    │ ≥ 8 字符                         │ passwordTooShort     │
│ 密码复杂度  │ 必含字母+数字 (推荐大小写+特殊)   │ passwordTooWeak      │
│ 二次确认    │ password === confirmPassword     │ passwordMismatch     │
│ 验证码      │ 6 位数字 /^\d{6}$/              │ enter6Digits         │
└────────────┴─────────────────────────────────┴──────────────────────┘
```

---

## Phase 2: 前端 UI

> 本 skill 不绑定 UI 库。下方代码用 React + 原生表单示例，项目可按自身 UI 库（shadcn/ui、MUI、Ant Design 等）适配。

### 2.1 AuthModal 视图状态机

```
type AuthTab = 'login' | 'register'
type AuthView = 'login' | 'register' | 'forgot-password'

              ┌──────────────┐
              │  AuthModal   │
              └──────┬───────┘
                     │
        ┌────────────┴─────────────┐
        ▼                          ▼
   authTab='login'            authTab='register'
        │                          │
        ▼                          ▼
  ┌─────────────┐          ┌──────────────────┐
  │ 邮箱+密码    │          │ ① 发验证码        │
  │ signInWith  │          │ signInWithOtp    │
  │ Password    │          │  (shouldCreate   │
  │             │          │   User:true)     │
  │ + OAuth 按钮 │          │ ② verifyOtp      │
  │             │          │ ③ updateUser     │
  └──────┬──────┘          │   (password+     │
         │                 │    nickname)     │
         │ "忘记密码?"      │ 校验:邮箱+密码复杂 │
         │                 │   +两次一致+6位码 │
         ▼                 └──────────────────┘
  ┌──────────────────┐
  │ view='forgot-    │
  │  password'       │
  │ ① 发验证码        │
  │ signInWithOtp    │
  │  (shouldCreate   │
  │   User:false)    │
  │ ② verifyOtp      │
  │ ③ updateUser     │
  │   (newPassword)  │
  │ 校验:邮箱+新密码  │
  │   复杂度+6位码    │
  └──────────────────┘
```

### 2.2 AuthModal 组件核心结构

```tsx
// components/auth-modal.tsx

interface AuthModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onLoginSuccess: () => void
}

// Props 说明:
// - open/onOpenChange: 由父组件控制显示/隐藏
// - onLoginSuccess: 登录/注册/改密成功回调 (通常只需触发，实际状态由 onAuthStateChange 监听)
```

**核心处理函数:**

```tsx
import { createClient } from '@/lib/supabase/client'
import {
  validateEmail,
  validatePassword,
  validateConfirmPassword,
  validateOtp,
} from '@/lib/auth-validation'

// ─── 登录: 邮箱+密码 ───
const handleLogin = async (e: React.FormEvent) => {
  e.preventDefault()
  if (!validateEmail(email)) { setError(msg('invalidEmail')); return }
  const pwdErr = validatePassword(password)
  if (pwdErr) { setError(msg(pwdErr)); return }

  const supabase = createClient()
  const { error } = await supabase.auth.signInWithPassword({
    email: email.trim(),
    password,
  })
  if (error) {
    // 错误映射 → invalidCredentials / emailNotConfirmed / loginFailed
    return
  }
  onLoginSuccess()
}

// ─── 注册: 发送验证码 ───
const handleRegisterSendOtp = async () => {
  if (!validateEmail(email)) { setError(msg('invalidEmail')); return }
  if (countdown > 0) return // 冷却中

  const supabase = createClient()
  const { error } = await supabase.auth.signInWithOtp({
    email: email.trim(),
    options: { shouldCreateUser: true },
  })
  if (error) {
    // rate limit → sendCodeRateLimit, 其他 → sendCodeFailed
    return
  }
  setOtpSent(true)
  setCountdown(50) // 启动 50s 冷却
}

// ─── 注册: 验证码 + 设密码 ───
const handleRegister = async (e: React.FormEvent) => {
  e.preventDefault()
  if (!validateEmail(email)) { setError(msg('invalidEmail')); return }
  if (!validateOtp(otp)) { setError(msg('enter6Digits')); return }
  const pwdErr = validatePassword(password)
  if (pwdErr) { setError(msg(pwdErr)); return }
  if (!validateConfirmPassword(password, confirmPassword)) {
    setError(msg('passwordMismatch')); return
  }

  const supabase = createClient()
  // 1. 验证 OTP
  const { error: otpError } = await supabase.auth.verifyOtp({
    email: email.trim(),
    token: otp.trim(),
    type: 'email',
  })
  if (otpError) {
    // codeExpired / codeIncorrect
    return
  }

  // 2. 设密码 + nickname
  const nickname = email.trim().split('@')[0]
  const { error: updateError } = await supabase.auth.updateUser({
    password,
    data: { nickname },
  })
  if (updateError) { setError(msg('signupFailed')); return }
  onLoginSuccess()
}

// ─── 忘记密码: 发送验证码 ───
const handleForgotSendOtp = async () => {
  if (!validateEmail(email)) { setError(msg('invalidEmail')); return }
  if (countdown > 0) return

  const supabase = createClient()
  const { error } = await supabase.auth.signInWithOtp({
    email: email.trim(),
    options: { shouldCreateUser: false }, // ← 关键: 已存在用户，不创建新用户
  })
  if (error) {
    // rate limit → sendCodeRateLimit, 其他 → sendCodeFailed
    return
  }
  setOtpSent(true)
  setCountdown(50)
}

// ─── 忘记密码: 验证码 + 设新密码 ───
const handleResetPassword = async (e: React.FormEvent) => {
  e.preventDefault()
  if (!validateEmail(email)) { setError(msg('invalidEmail')); return }
  if (!validateOtp(otp)) { setError(msg('enter6Digits')); return }
  const pwdErr = validatePassword(newPassword)
  if (pwdErr) { setError(msg(pwdErr)); return }

  const supabase = createClient()
  // 1. 验证 OTP
  const { error: otpError } = await supabase.auth.verifyOtp({
    email: email.trim(),
    token: otp.trim(),
    type: 'email',
  })
  if (otpError) {
    // codeExpired / codeIncorrect
    return
  }

  // 2. 设新密码
  const { error: updateError } = await supabase.auth.updateUser({
    password: newPassword,
  })
  if (updateError) { setError(msg('changePasswordFailed')); return }
  onLoginSuccess()
}
```

> `msg(key)` 是项目自身的消息取值函数（i18n 或硬编码文案），本 skill 不规定其实现。

### 2.3 UI 布局示意

**登录视图:**
```
┌─────────────────────────────────────┐
│  📧 欢迎登录                        │
├─────────────────────────────────────┤
│  [🟡 Sign in with Google]           │
│  [⚫ Sign in with GitHub]           │
│                                     │
│  ─────── or use email ────────      │
│                                     │
│  📧 [Email_______________]          │
│  🔒 [Password__________👁]          │
│                                     │
│  [        Log in         ]          │
│                                     │
│  Forgot password?                   │
│  Don't have an account? Sign up     │
└─────────────────────────────────────┘
```

**注册视图 (含验证码+确认密码):**
```
┌─────────────────────────────────────┐
│  ✨ 创建账号                        │
│  验证码已发送至 xxx@xx.com          │
├─────────────────────────────────────┤
│  📧 [Email_______________] [Send]   │ ← 发送验证码(50s冷却)
│                                     │
│  🔢 [______]  6位验证码             │
│  🔒 [Password__________👁]          │ ← ≥8位+字母+数字
│  🔒 [Confirm__________👁]          │ ← 二次确认
│                                     │
│  [      Sign up        ]            │
│                                     │
│  Already have an account? Log in    │
└─────────────────────────────────────┘
```

**忘记密码视图 (验证码改密):**
```
┌─────────────────────────────────────┐
│  🔑 重置密码                        │
├─────────────────────────────────────┤
│  📧 [Email_______________] [Send]   │ ← 发验证码(shouldCreateUser:false)
│                                     │
│  🔢 [______]  6位验证码             │
│  🔒 [New Password_____👁]          │ ← ≥8位+字母+数字
│                                     │
│  [    Reset password    ]           │
│                                     │
│  Back to login                      │
└─────────────────────────────────────┘
```

### 2.4 OAuth Provider 配置

Supabase Dashboard 配置 (非代码):
```
Supabase Dashboard → Authentication → Providers

需要启用的 Provider:
├── Google  → 需要 Google Cloud Console 的 Client ID + Secret
└── GitHub  → 需要 GitHub Settings → Developer 的 Client ID + Secret

回调 URL 统一填: https://你的域名/auth/callback
```

代码中无需配置 Client ID/Secret，只需调用:
```typescript
supabase.auth.signInWithOAuth({
  provider: 'google', // 或 'github'
  options: { redirectTo: `${window.location.origin}/auth/callback` }
})
```

### 2.5 重发冷却倒计时 (50s)

```tsx
const [countdown, setCountdown] = useState(0)
const countdownRef = useRef<ReturnType<typeof setInterval> | null>(null)

useEffect(() => {
  if (countdown > 0) {
    countdownRef.current = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          if (countdownRef.current) clearInterval(countdownRef.current)
          return 0
        }
        return prev - 1
      })
    }, 1000)
  }
  return () => {
    if (countdownRef.current) clearInterval(countdownRef.current)
  }
}, [countdown > 0]) // eslint-disable-line react-hooks/exhaustive-deps

// 发送验证码成功后: setCountdown(50)
// 按钮禁用条件: countdown > 0
// 按钮文案: countdown > 0 ? msg('resendInXs', { sec: countdown }) : msg('resend')
```

---

## Phase 3: 回调路由

> 回调路由放在 `app/auth/` 下，**不在** i18n 的 `[locale]` 路由段内（因为 Supabase 回调不带 locale 前缀）。若项目无 i18n，放 `app/auth/` 即可。

### 3.1 OAuth 回调

**`app/auth/callback/route.ts`**:
```typescript
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

/** 仅允许相对路径，防止开放重定向 */
function sanitizeNext(next: string | null): string {
  if (!next) return '/'
  return next.startsWith('/') && !next.startsWith('//') ? next : '/'
}

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = sanitizeNext(searchParams.get('next'))

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }
  }

  return NextResponse.redirect(`${origin}/?auth=error`)
}
```

### 3.2 邮箱确认兜底路由（含安全加固）

**`app/auth/confirm/route.ts`**:
```typescript
import { createClient } from '@/lib/supabase/server'
import { NextRequest, NextResponse } from 'next/server'

const VALID_TYPES = ['email', 'signup', 'recovery', 'magiclink', 'invite'] as const
type AuthType = (typeof VALID_TYPES)[number]

/** 仅允许相对路径，防止开放重定向 */
function sanitizeNext(next: string | null): string {
  if (!next) return '/'
  return next.startsWith('/') && !next.startsWith('//') ? next : '/'
}

/** type 参数白名单校验 */
function validateType(type: string | null): AuthType | null {
  if (!type) return null
  return VALID_TYPES.includes(type as AuthType) ? (type as AuthType) : null
}

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)
  const tokenHash = searchParams.get('token_hash')
  const type = validateType(searchParams.get('type'))
  const next = sanitizeNext(searchParams.get('next'))

  if (tokenHash && type) {
    const supabase = await createClient()
    const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }
  }

  return NextResponse.redirect(`${origin}/?auth=error`)
}
```

> **注意**: 本方案注册/改密均在前端用 `verifyOtp({ email, token, type:'email' })` 直接验证，不依赖邮件链接。`confirm` 路由仅作 magic link 兜底，已加 `sanitizeNext` 防开放重定向 + `validateType` 白名单。

---

## Phase 4: 构建验证

```bash
pnpm build
```

验证清单:
- [ ] 构建通过，无 TypeScript 错误
- [ ] 登录: 邮箱+密码 可登录
- [ ] 登录: Google / GitHub OAuth 可跳转
- [ ] 注册: 邮箱 → 收验证码 → 输入验证码+密码+确认密码 → 注册成功
- [ ] 注册校验: 邮箱格式/密码≥8+复杂度/两次一致/6位验证码 均拦截
- [ ] 忘记密码: 邮箱 → 收验证码 → 输入验证码+新密码 → 改密成功
- [ ] 改密校验: 邮箱格式/新密码≥8+复杂度/6位验证码 均拦截
- [ ] 重发冷却: 50s 内按钮禁用
- [ ] 回调路由: /auth/callback 和 /auth/confirm 存在且安全加固生效

---

## 错误消息键名清单

错误映射需要以下消息 key（若项目使用 i18n）。键名通用，具体文案由项目按自身语言方案提供:

```
invalidEmail / invalidCredentials / emailNotConfirmed / unsupportedProvider
loginFailed / signupFailed / changePasswordFailed / emailAlreadyExists
passwordTooShort / passwordTooWeak / passwordMismatch / passwordSameAsOld
passwordRateLimit
sendCodeFailed / sendCodeRateLimit / codeExpired / codeIncorrect / enter6Digits
codeSentTo / resend / resendInXs / passwordResetSuccess
```

> **注**: 本 skill 不绑定特定 i18n 框架。项目用 next-intl / react-i18next / 原生方案均可，自行落地这些 key 的多语言文案。

---

## 关键文件清单

| 文件 | 职责 | Phase |
|------|------|-------|
| `lib/supabase/client.ts` | 浏览器端 Supabase SDK | 1 |
| `lib/supabase/server.ts` | 服务端 Supabase SDK | 1 |
| `lib/auth-validation.ts` | 邮箱/密码/验证码统一校验 | 1 |
| `middleware.ts` (或 `proxy.ts`) | Session cookie 刷新 | 1 |
| `app/auth/callback/route.ts` | OAuth 回调（含安全加固） | 3 |
| `app/auth/confirm/route.ts` | 邮箱确认兜底（含安全加固） | 3 |
| `components/auth-modal.tsx` | 登录/注册/忘记密码 UI | 2 |
| `.env.example` | Supabase 环境变量模板 | 1 |

---

## 实现注意事项

1. **统一 OTP 方案**: 注册与改密均走「signInWithOtp → verifyOtp → updateUser」三步，不使用 `signUp` 和 `resetPasswordForEmail`。区别仅在 `shouldCreateUser`（注册=true / 改密=false）。
2. **前端校验先行**: 邮箱格式、密码长度(≥8)、密码复杂度(字母+数字)、二次确认一致、验证码6位，全部前端拦截，减少无效请求。
3. **Supabase Dashboard 配置**: OAuth Provider、邮件模板、确认策略都在 Dashboard 配置，不在代码中。
4. **邮箱确认策略**: Dashboard → Authentication → Email → "Confirm email" 开关。本方案前端直接 verifyOtp，建议关闭"发送确认链接"或保留作兜底。
5. **回调路由在 i18n 路由段外**: `app/auth/callback` 和 `app/auth/confirm` 不在 `[locale]/` 下。
6. **安全加固**: confirm/callback 路由用 `sanitizeNext` 防开放重定向，`validateType` 白名单限制 type。
7. **重发冷却**: 50 秒倒计时，防止滥用 Supabase 邮件发送（有频率限制）。
8. **零新依赖**: Supabase Auth 全部功能已包含在 `@supabase/supabase-js` + `@supabase/ssr` 中。
9. **已有文件不覆盖**: Phase 0 检测到已有文件时跳过，只创建缺失的。
10. **与项目解耦**: 本 skill 不绑定 i18n 框架、语言组合、UI 库。`msg(key)` 取文案的方式由项目自定。
