# Desktop Rules — Global

**Version:** 1.0 | **Scope:** Desktop apps. Tauri sections apply when the project has `src-tauri/`.
**Reference skills:** `tauri-best-practices`, `desktop-app-best-practices`.

---

## ALL DESKTOP APPS

- Settings the user expects to survive a restart use `localStorage` with versioned keys or the OS
  app-data folder, never `sessionStorage`. One-shot handoffs read in an event handler and then
  removed may use `sessionStorage`
- Everything compiled into the app ships in the installer. Secrets belong in a backend
- External URLs open in the system browser, never inside the app window

---

## TAURI SHELL

| Rule | Signal |
|---|---|
| Rust code lives in `src-tauri/src/`; plugins are registered in `lib.rs` via `.plugin(...)` | Plugin crate in `Cargo.toml` with no `.plugin(` in `lib.rs` |
| Every plugin or core API used from JS has a matching permission in `src-tauri/capabilities/` | `@tauri-apps/plugin-x` imported with no `x:default` or `x:allow-*` permission |
| Every Tauri call is guarded for the non-Tauri runtime, so the frontend still runs in a plain browser | `invoke(...)` or a plugin call with no `isDesktop()` on the path |
| Tauri JS APIs are imported **only** in `src/config/` or `src/hooks/UseDesktop*/`, wrapped in a hook or helper | `@tauri-apps/...` import inside `src/components/` or `src/app/` |
| External URLs go through the opener plugin wrapper, never `<a target="_blank">` or `window.open` | Webview navigates away from the app with no back button |
| `security.csp` in `tauri.conf.json` is set, not `null`, once the app's origins are known | `"csp": null` |
| `capabilities/` grants only the permissions the code uses | `core:default` plus wildcard `allow-*` sets |

The runtime guard lives once, in `src/config/desktop.ts`:

```ts
export const isDesktop = (): boolean =>
  typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
```

Every `UseDesktop*` hook needs a browser fallback branch.

---

## NEXT.JS STATIC EXPORT IN A DESKTOP SHELL

With `output: 'export'` nothing runs on a server after the build. These build, then fail or
silently do nothing inside the shell:

| Forbidden | Why |
|---|---|
| `proxy.ts`, `middleware.ts` | Runs on a server per request |
| `src/app/api/**` route handlers | `out/` is static files |
| `'use server'`, Server Actions | POST to a server that does not exist |
| `async` Server Components fetching per-user data | Runs once at build time with no user |
| `cookies()`, `headers()`, `draftMode()` | There is no request |
| Dynamic segments without `generateStaticParams` | Export has no router to resolve them |
| `next/image` optimisation | Needs the image server; set `images.unoptimized` |
| `redirects`, `rewrites`, `headers` in `next.config.ts` | Served by the Next server, not static hosting |
| Node built-ins in `src/` | Browser runtime; native access goes through Tauri commands |

**Still works:** Server Components that render once at build time to compose static shells, static
`metadata`, every client hook, client-side navigation. Route protection is client-side: a guard in
the protected group's `layout.tsx`.

The server-first advice in `next-best-practices` does not apply in this setup. All data access is
client-side TanStack Query against the external API.
