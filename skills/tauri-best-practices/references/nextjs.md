# Next.js with Tauri

Tauri does not support server-based solutions, so Next.js must run as a static export. The official guide was written for Next.js 14.2.3, so check the bundled docs of the version you have installed.

## Configuration

```json
// src-tauri/tauri.conf.json
{
  "build": {
    "beforeDevCommand": "pnpm dev",
    "beforeBuildCommand": "pnpm build",
    "devUrl": "http://localhost:3000",
    "frontendDist": "../out"
  }
}
```

```ts
// next.config
const isProd = process.env.NODE_ENV === 'production';
const internalHost = process.env.TAURI_DEV_HOST || 'localhost';

const nextConfig = {
  output: 'export',                 // SSG, not SSR
  images: { unoptimized: true },    // next/image needs this in an export
  // Without this the dev server does not resolve assets
  assetPrefix: isProd ? undefined : `http://${internalHost}:3000`,
};
```

## What this means for app code

`pnpm build` can succeed on features that then fail or do nothing in the shell, so a green build proves little. Treat these as unavailable:

- Middleware or `proxy.ts`, API route handlers, and Server Actions
- `cookies()`, `headers()`, and other request-scoped APIs
- Per-user data in Server Components, which would be frozen at build time
- Dynamic segments without `generateStaticParams`
- `redirects`, `rewrites`, and `headers` in the Next config
- Node built-ins in frontend code. Use a Tauri command for native access

What works: Server Components that render once at build time, static `metadata`, client hooks, and client-side navigation. Fetch data on the client, and move route protection into a client guard.

## Keeping the browser working

Guard every Tauri call so the frontend still runs under plain `next dev`, which makes UI work much faster.

```ts
export const isDesktop = (): boolean =>
  typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
```

Load Tauri modules with a dynamic `import()` behind that guard, so they never run in the prerender or the browser.
