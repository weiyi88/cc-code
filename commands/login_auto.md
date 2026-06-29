# Supabase Auth 通用登录系统实现指南

统一使用 Supabase Auth，零新依赖，覆盖完整登录功能。

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
├── middleware.ts → 包含 supabase session 刷新?
├── .env.local → NEXT_PUBLIC_SUPABASE_URL + ANON_KEY 存在?
├── messages/*.json → Auth 命名空间存在? 哪些语言?
└── app/auth/callback/route.ts 存在?
```

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

**`middleware.ts`** — 在已有 middleware 中追加 Supabase session 刷新逻辑:

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

> **注意**: 如果项目有 next-intl 等 middleware，Supabase 刷新应放在最后执行。

### 1.4 四大认证能力 — Supabase API 映射

```
┌──────────────────┬──────────────────────────────────────────────┐
│  功能            │  Supabase Auth API                           │
├──────────────────┼──────────────────────────────────────────────┤
│  ① 邮箱+密码注册 │  supabase.auth.signUp({                     │
│                  │    email, password,                          │
│                  │    options: { data: { name } }               │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ① 邮箱+密码登录 │  supabase.auth.signInWithPassword({          │
│                  │    email, password                           │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ② 邮箱+验证码   │  发送: supabase.auth.signInWithOtp({        │
│                  │    email,                                    │
│                  │    options: { emailRedirectTo }              │
│                  │  })                                          │
│                  │  验证: supabase.auth.verifyOtp({             │
│                  │    email, token, type: 'email'               │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ③ OAuth 登录    │  supabase.auth.signInWithOAuth({             │
│                  │    provider: 'google' | 'github' | 'apple', │
│                  │    options: { redirectTo }                   │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ④ 修改密码      │  supabase.auth.updateUser({                 │
│                  │    password: newPassword                     │
│                  │  })                                          │
├──────────────────┼──────────────────────────────────────────────┤
│  ④ 重置密码      │  supabase.auth.resetPasswordForEmail(       │
│   (忘记密码)     │    email,                                   │
│                  │    options: { redirectTo }                   │
│                  │  )                                           │
│                  │  → Supabase 发送重置邮件                     │
│                  │  → 用户点击链接进入重置页面                   │
│                  │  → supabase.auth.updateUser({ password })   │
├──────────────────┼──────────────────────────────────────────────┤
│  退出登录        │  supabase.auth.signOut()                    │
├──────────────────┼──────────────────────────────────────────────┤
│  监听状态变化    │  supabase.auth.onAuthStateChange(callback)   │
├──────────────────┼──────────────────────────────────────────────┤
│  获取当前用户    │  supabase.auth.getUser()                    │
└──────────────────┴──────────────────────────────────────────────┘
```

### 1.5 错误映射 (Supabase → 用户友好消息)

```
Supabase error.message              →  i18n key
─────────────────────────────────────────────────────
"Invalid login credentials"          →  invalidCredentials
"Email not confirmed"                →  emailNotConfirmed
"User already registered"            →  emailAlreadyExists
"Password should be at least 6..."   →  passwordTooShort
"New password should be different"   →  passwordSameAsOld
"Token has expired or is invalid"    →  codeExpired
"For security purposes, you can..."  →  passwordRateLimit
其他                                  →  loginFailed / signupFailed
```

---

## Phase 2: 前端 UI

### 2.1 AuthModal 视图状态机

```
type AuthView = 'email' | 'otp' | 'reset-password' | 'confirm-email'
type EmailMethod = 'code' | 'password'
type PasswordMode = 'login' | 'signup'

                 ┌──────────────┐
                 │ view='email' │ ◄── 默认入口
                 └──────┬───────┘
                        │
              ┌─────────┴──────────┐
              │                    │
     emailMethod='code'    emailMethod='password'
              │                    │
              │           ┌───────┴────────┐
              │      login模式          signup模式
              │           │                │
              ▼           ▼                ▼
         signInWithOtp  signInWithPassword  signUp
              │           │                │
              ▼           │                ▼
      view='otp'         │         session存在?
      verifyOtp          │         ├── 是 → ✅ 登录
              │           │         └── 否 → view='confirm-email'
              ▼           ▼
           ✅ 登录     ✅ 登录

  密码管理入口 (从 email 视图的密码模式进入):
  ┌──────────────────┐     ┌───────────────────┐
  │ "忘记密码?" 链接  │────►│ view='reset-password'│
  │  (login模式可见)  │     │ 输入邮箱 → 发送重置信│
  └──────────────────┘     │ 输入新密码 → 重置    │
                           └───────────────────┘
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
// - onLoginSuccess: 登录成功回调 (通常只需触发，实际状态由 onAuthStateChange 监听)
```

**UI 布局 (email 视图, 密码模式, login):**

```
┌─────────────────────────────────────┐
│  📧 登录 / 注册                     │
│  选择你喜欢的登录方式               │
├─────────────────────────────────────┤
│                                     │
│  [🟡 Sign in with Google]           │
│  [⚫ Sign in with GitHub]           │
│  (按需添加更多 OAuth)               │
│                                     │
│  ─────── or use email ────────      │
│                                     │
│  ┌──────────────┬──────────────┐    │
│  │  Send Code   │   Password   │    │  ← 方法切换
│  └──────────────┴──────────────┘    │
│                                     │
│  📧 [Email_______________]          │
│  🔒 [Password__________👁]          │
│                                     │
│  [        Log in         ]          │
│                                     │
│  Forgot password?                   │  ← 密码模式 login 可见
│  Don't have an account? Sign up     │  ← 模式切换
│                                     │
└─────────────────────────────────────┘
```

### 2.3 OAuth Provider 配置

Supabase Dashboard 配置 (非代码):
```
Supabase Dashboard → Authentication → Providers

需要启用的 Provider:
├── Google  → 需要 Google Cloud Console 的 Client ID + Secret
├── GitHub  → 需要 GitHub Settings → Developer 的 Client ID + Secret
├── Apple   → 需要 Apple Developer 账号
├── Discord → 需要 Discord Developer Portal 的 Client ID + Secret
└── 更多    → 按需在 Dashboard 开启

回调 URL 统一填: https://你的域名/auth/callback
```

代码中无需配置 Client ID/Secret，只需调用:
```typescript
supabase.auth.signInWithOAuth({
  provider: 'google', // 或 'github', 'apple', 'discord' 等
  options: { redirectTo: `${origin}/auth/callback` }
})
```

### 2.4 密码管理 UI

**修改密码** (已登录状态):
- 在用户设置/个人资料页面添加
- 表单: 旧密码 + 新密码 + 确认新密码
- 调用: `supabase.auth.updateUser({ password: newPassword })`

**重置密码** (未登录 / 忘记密码):
- 从 AuthModal 的 "Forgot password?" 链接进入
- 步骤 1: 输入邮箱 → `supabase.auth.resetPasswordForEmail(email, { redirectTo })`
- 步骤 2: Supabase 发送重置邮件，用户点击链接
- 步骤 3: 链接跳转到 `/auth/callback?type=recovery` → 回调路由处理
- 步骤 4: 跳转到重置密码页面 → `supabase.auth.updateUser({ password })`

### 2.5 重置密码页面

**`app/[locale]/reset-password/page.tsx`**:
- 服务端: 检查是否有有效 session (从 recovery 链接来)
- 客户端: 新密码 + 确认新密码表单
- 提交: `supabase.auth.updateUser({ password: newPassword })`
- 成功: 重定向到首页

---

## Phase 3: 回调路由

### 3.1 OAuth 回调

**`app/auth/callback/route.ts`**:
```typescript
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

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

### 3.2 邮箱确认

**`app/auth/confirm/route.ts`**:
```typescript
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const tokenHash = searchParams.get('token_hash')
  const type = searchParams.get('type') as 'email' | 'signup' | 'recovery' | null
  const next = searchParams.get('next') ?? '/'

  if (tokenHash && type) {
    const supabase = await createClient()
    const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
    if (!error) {
      // recovery 类型跳转到重置密码页
      if (type === 'recovery') {
        return NextResponse.redirect(`${origin}/reset-password`)
      }
      return NextResponse.redirect(`${origin}${next}`)
    }
  }

  return NextResponse.redirect(`${origin}/?auth=error`)
}
```

> **注意**: `type='recovery'` 是重置密码邮件链接，需跳转到重置密码页面。

### 3.3 路由位置

回调路由在 `app/auth/` 下，**不在** `app/[locale]/` 下 (因为 Supabase 回调不带 locale 前缀)。

---

## Phase 4: 构建验证

```bash
pnpm build
```

验证清单:
- [ ] 构建通过，无 TypeScript 错误
- [ ] 启动 dev server，打开 AuthModal
- [ ] 验证码模式: 输入邮箱 → 切换可见
- [ ] 密码模式: 输入邮箱+密码 → 登录/注册切换
- [ ] OAuth 按钮: Google / GitHub 可点击
- [ ] 忘记密码: 链接可见，点击进入重置流程
- [ ] i18n: 切换语言，所有文本正确显示
- [ ] 回调路由: /auth/callback 和 /auth/confirm 存在

---

## i18n 翻译键 (Auth 命名空间)

所有语言文件 (messages/en.json, zh.json, ja.json 等) 的 Auth 命名空间必须包含以下键:

```json
{
  "loginOrSignup": "Log in / Sign up",
  "enterVerificationCode": "Enter verification code",
  "chooseLoginMethod": "Choose your preferred login method",
  "codeSentTo": "Verification code sent to {email}",
  "googleLogin": "Sign in with Google",
  "githubLogin": "Sign in with GitHub",
  "orUseEmail": "or use email",
  "emailPlaceholder": "Email",
  "sendCode": "Send code",
  "sixDigits": "6-digit",
  "verificationCodePlaceholder": "Enter verification code",
  "verifyAndLogin": "Verify and log in",
  "changeEmail": "Change email",
  "resendIn60s": "Resend in 60s",
  "resend": "Resend",
  "unsupportedProvider": "This login method is not supported",
  "loginFailed": "Login failed, please try again",
  "invalidEmail": "Please enter a valid email",
  "sendCodeFailed": "Failed to send verification code, please try again",
  "enter6Digits": "Please enter the 6-digit code",
  "codeExpired": "Incorrect or expired code, please try again",

  "usePasswordInstead": "Password",
  "passwordPlaceholder": "Password",
  "namePlaceholder": "Nickname (optional)",
  "loginButton": "Log in",
  "signupButton": "Sign up",
  "createAccount": "Create account",
  "signupDescription": "Sign up to save your game progress",
  "passwordTooShort": "Password must be at least 6 characters",
  "invalidCredentials": "Invalid email or password",
  "emailNotConfirmed": "Please verify your email first",
  "emailAlreadyExists": "This email is already registered. Try logging in.",
  "signupFailed": "Sign up failed, please try again",
  "noAccount": "Don't have an account?",
  "hasAccount": "Already have an account?",
  "showPassword": "Show password",
  "hidePassword": "Hide password",
  "confirmEmailTitle": "Check your email",
  "confirmEmailMsg": "We've sent a confirmation link to {email}",
  "confirmEmailHint": "Click the link in your email to verify your account, then come back to log in.",
  "backToLogin": "Back to login",

  "forgotPassword": "Forgot password?",
  "resetPasswordTitle": "Reset password",
  "resetPasswordDescription": "Enter your email and we'll send you a reset link.",
  "sendResetLink": "Send reset link",
  "resetLinkSent": "Reset link sent! Check your email.",
  "resetLinkSentMsg": "We've sent a password reset link to {email}",
  "newPassword": "New password",
  "confirmNewPassword": "Confirm new password",
  "passwordMismatch": "Passwords do not match",
  "resetPasswordButton": "Reset password",
  "passwordResetSuccess": "Password reset successfully!",
  "changePasswordTitle": "Change password",
  "currentPassword": "Current password",
  "newPasswordLabel": "New password",
  "changePasswordButton": "Change password",
  "passwordSameAsOld": "New password must be different from current password",
  "passwordRateLimit": "Too many attempts, please wait a moment",
  "passwordChanged": "Password changed successfully"
}
```

### 各语言翻译参考

**中文 (zh):**
```json
{
  "forgotPassword": "忘记密码？",
  "resetPasswordTitle": "重置密码",
  "resetPasswordDescription": "输入你的邮箱，我们将发送重置链接。",
  "sendResetLink": "发送重置链接",
  "resetLinkSent": "重置链接已发送！请查收邮件。",
  "resetLinkSentMsg": "我们已向 {email} 发送了密码重置链接",
  "newPassword": "新密码",
  "confirmNewPassword": "确认新密码",
  "passwordMismatch": "两次密码输入不一致",
  "resetPasswordButton": "重置密码",
  "passwordResetSuccess": "密码重置成功！",
  "changePasswordTitle": "修改密码",
  "currentPassword": "当前密码",
  "newPasswordLabel": "新密码",
  "changePasswordButton": "修改密码",
  "passwordSameAsOld": "新密码不能与当前密码相同",
  "passwordRateLimit": "尝试次数过多，请稍后再试",
  "passwordChanged": "密码修改成功"
}
```

**日文 (ja):**
```json
{
  "forgotPassword": "パスワードをお忘れですか？",
  "resetPasswordTitle": "パスワードリセット",
  "resetPasswordDescription": "メールアドレスを入力すると、リセットリンクを送信します。",
  "sendResetLink": "リセットリンクを送信",
  "resetLinkSent": "リセットリンクを送信しました！メールをご確認ください。",
  "resetLinkSentMsg": "{email} にパスワードリセットリンクを送信しました",
  "newPassword": "新しいパスワード",
  "confirmNewPassword": "新しいパスワードの確認",
  "passwordMismatch": "パスワードが一致しません",
  "resetPasswordButton": "パスワードをリセット",
  "passwordResetSuccess": "パスワードのリセットが完了しました！",
  "changePasswordTitle": "パスワード変更",
  "currentPassword": "現在のパスワード",
  "newPasswordLabel": "新しいパスワード",
  "changePasswordButton": "パスワードを変更",
  "passwordSameAsOld": "新しいパスワードは現在のパスワードと異なる必要があります",
  "passwordRateLimit": "試行回数が多すぎます。しばらくお待ちください",
  "passwordChanged": "パスワードを変更しました"
}
```

---

## 关键文件清单

| 文件 | 职责 | Phase |
|------|------|-------|
| `lib/supabase/client.ts` | 浏览器端 Supabase SDK | 1 |
| `lib/supabase/server.ts` | 服务端 Supabase SDK | 1 |
| `middleware.ts` | Session cookie 刷新 | 1 |
| `app/auth/callback/route.ts` | OAuth + 密码重置回调 | 3 |
| `app/auth/confirm/route.ts` | 邮箱确认回调 | 3 |
| `components/auth-modal.tsx` | 登录/注册/OTP/重置密码 UI | 2 |
| `app/[locale]/reset-password/page.tsx` | 重置密码页面 | 2 |
| `messages/{en,zh,ja}.json` | Auth 命名空间翻译 | 2 |
| `.env.example` | Supabase 环境变量模板 | 1 |

---

## 实现注意事项

1. **Supabase Dashboard 配置优先**: OAuth Provider、邮件模板、确认策略都在 Dashboard 配置，不在代码中
2. **邮箱确认策略**: Dashboard → Authentication → Email → "Confirm email" 开关决定注册后是否需要确认
3. **密码重置邮件模板**: Dashboard → Authentication → Email Templates → "Reset Password" 可自定义
4. **回调路由在 [locale] 外**: `app/auth/callback` 和 `app/auth/confirm` 不在 `app/[locale]/` 下
5. **recovery 类型需特殊处理**: `/auth/confirm?type=recovery` 应跳转到重置密码页
6. **i18n 规则**: 客户端组件用 `useTranslations('Auth')`，服务端组件用 `getTranslations({ locale, namespace: 'Auth' })`
7. **零新依赖**: Supabase Auth 全部功能已包含在 `@supabase/supabase-js` + `@supabase/ssr` 中
8. **已有文件不覆盖**: Phase 0 检测到已有文件时跳过，只创建缺失的
