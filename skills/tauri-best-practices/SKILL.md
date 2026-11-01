---
name: tauri-best-practices
description: Tauri v2 best practices for security, IPC, Rust commands, state, plugins, Next.js static export, Windows installers, WebView2, code signing, the updater, and testing. Use whenever the work touches src-tauri, tauri.conf.json, capabilities, permissions, CSP, invoke, Tauri commands, events or channels, @tauri-apps packages, tauri-plugin crates, sidecars, or packaging and releasing a Tauri app, even if the user only says "desktop app" and the project has a src-tauri folder.
metadata:
  author: phoxer
  sourceDocs: tauri-apps/tauri-docs@ec113a503f (branch v2)
  tauriVersion: "2.12.5"
---

# Tauri Best Practices

Rules for Tauri v2 apps, taken from the official docs. Read the reference file for the area you are touching before writing code: Tauri's security model has several defaults that surprise people coming from Electron or the web.

Project instructions win over this skill. When the installed Tauri version differs from the version above, check the docs for that version.

## The model to keep in mind

Tauri assumes **the webview is insecure**. Rust code is the trusted side, and every message from the frontend crosses a trust boundary. Treat a command as you would a public API endpoint: validate its input and grant the least access that works.

## Rules by priority

| Priority | Rule | Reference |
|---|---|---|
| CRITICAL | Set a CSP. It is off unless configured, so `"csp": null` means no protection | [security](references/security.md) |
| CRITICAL | Grant the smallest capabilities per window. Never add wildcards to silence an error | [security](references/security.md) |
| CRITICAL | Validate command input in Rust. Capabilities do not protect against a careless command | [security](references/security.md) |
| CRITICAL | Back up the updater private key. Losing it means installed apps can never update again | [distribution](references/distribution.md) |
| HIGH | Your own commands are open to **all** windows by default. Restrict them with `AppManifest::commands` when windows differ in trust | [security](references/security.md) |
| HIGH | Commands for request and response, channels for streams, events for small notifications | [ipc](references/ipc.md) |
| HIGH | `async` for heavy work. Commands without it run on the main thread and freeze the UI | [ipc](references/ipc.md) |
| HIGH | Register `single-instance` as the **first** plugin | [distribution](references/distribution.md) |
| HIGH | Next.js needs `output: 'export'`. Tauri does not support server-based solutions | [nextjs](references/nextjs.md) |
| HIGH | Sign every release with the same certificate. SmartScreen reputation builds over time, even with EV | [distribution](references/distribution.md) |
| MEDIUM | Use a typed error enum that implements `serde::Serialize`, not `String` | [ipc](references/ipc.md) |
| MEDIUM | Do not wrap managed state in `Arc`. Tauri already does | [ipc](references/ipc.md) |
| MEDIUM | Use the Isolation pattern when the app has a large frontend dependency tree | [security](references/security.md) |
| MEDIUM | Call `clearMocks()` after each test that uses `mockIPC` | [testing](references/testing.md) |

## When to read what

| Task | Read |
|---|---|
| Editing `capabilities/`, CSP, permissions, or scopes; adding a plugin; reviewing security | [references/security.md](references/security.md) |
| Writing commands, events, channels, or Rust state | [references/ipc.md](references/ipc.md) |
| Setting up or debugging Next.js in Tauri | [references/nextjs.md](references/nextjs.md) |
| Installers, WebView2, signing, the updater, deep links, single instance, sidecars | [references/distribution.md](references/distribution.md) |
| Unit, integration, or end-to-end tests | [references/testing.md](references/testing.md) |

## Sources

Official Tauri docs, `tauri-apps/tauri-docs` branch `v2` at commit `ec113a503f` (2026-10-27): `security/*`, `concept/Inter-Process Communication/isolation`, `develop/calling-rust`, `develop/calling-frontend`, `develop/state-management`, `develop/sidecar`, `develop/Tests/*`, `distribute/windows-installer`, `distribute/Sign/windows`, `plugin/*`, and `start/frontend/nextjs`.
