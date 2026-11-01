---
name: desktop-app-best-practices
description: Framework-neutral best practices for desktop applications, focused on Windows 11, covering window behavior, resizing, DPI and scaling, keyboard and accessibility, error messages, dialogs, notifications, installers, updates, uninstall, where to store app data, credentials, and privacy. Use whenever building, reviewing, or designing a desktop app, including Tauri, Electron, or WinUI projects, or whenever the user asks how an app should behave on Windows, how to install or update it, or where to keep its data, even if they do not say "best practices".
metadata:
  author: phoxer
---

# Desktop App Best Practices

A desktop app lives in the user's operating system. People expect it to behave like their other apps, survive being resized and restarted, and clean up after itself. A web UI in a window does not get these for free.

Use this skill alongside the framework skill. For a Tauri app, `tauri-best-practices` covers how to do these things, and this skill covers what the app should do. Project instructions win over both.

## Rules by priority

| Priority | Rule | Reference |
|---|---|---|
| CRITICAL | Do not require admin rights to install or run | [install-and-update](references/install-and-update.md) |
| CRITICAL | Keep credentials in a platform credential store, never in source, config, logs, or the binary | [data-and-privacy](references/data-and-privacy.md) |
| CRITICAL | Sign every executable, not just the installer | [install-and-update](references/install-and-update.md) |
| HIGH | Keep user content in user folders, and app data in per-user app data folders | [data-and-privacy](references/data-and-privacy.md) |
| HIGH | Make every action reachable by keyboard, with a visible focus indicator | [ui-conventions](references/ui-conventions.md) |
| HIGH | Keep the UI usable at small window sizes, snap layouts, and high scaling | [window-and-layout](references/window-and-layout.md) |
| HIGH | Let users restart for updates when convenient, and save state first | [install-and-update](references/install-and-update.md) |
| HIGH | Keep working offline, and show what is unavailable | [window-and-layout](references/window-and-layout.md) |
| MEDIUM | Respect the system theme and contrast themes | [window-and-layout](references/window-and-layout.md) |
| MEDIUM | Write errors that say what happened and how to fix it | [ui-conventions](references/ui-conventions.md) |
| MEDIUM | Measure cold start on low-end hardware | [window-and-layout](references/window-and-layout.md) |

## When to read what

| Task | Read |
|---|---|
| Window sizing, DPI, themes, title bar, offline, performance | [references/window-and-layout.md](references/window-and-layout.md) |
| Keyboard, focus, dialogs, errors, notifications, wording | [references/ui-conventions.md](references/ui-conventions.md) |
| Installers, updates, uninstall, signing, Windows on Arm | [references/install-and-update.md](references/install-and-update.md) |
| Storage locations, secrets, telemetry, consent | [references/data-and-privacy.md](references/data-and-privacy.md) |

## Release check

Before shipping, confirm each of these on a clean machine with a standard user account:

- [ ] Installs and runs without an admin prompt
- [ ] Appears in Settings > Apps > Installed apps, and uninstalls cleanly
- [ ] Reopens at the last window size and position
- [ ] Works at 100%, 150%, and 200% scaling, and at 200% text scaling
- [ ] Works when snapped to half and quarter of the screen
- [ ] Every action works by keyboard, and a contrast theme stays readable
- [ ] Starts and shows something useful with no network
- [ ] An update installs without losing unsaved work
- [ ] All binaries are signed
- [ ] Nothing sensitive appears in logs

## Sources

Microsoft Learn: [Windows app development best practices](https://learn.microsoft.com/en-us/windows/apps/get-started/best-practices) (updated 2026-10-07), [UX checklist for desktop applications](https://learn.microsoft.com/en-us/windows/win32/uxguide/top-violations) (written for Windows 7, so its principles apply but not its visuals), and [Known folders](https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid).
