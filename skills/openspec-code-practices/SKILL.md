---
name: openspec-code-practices
description: Mandatory code-practices gate for OpenSpec work. Loads the installed best-practice skills (Next.js, React, composition, view transitions, React Native, MUI, web design, Tauri, desktop apps) before writing an OpenSpec design.md / tasks.md and before implementing tasks with openspec apply. Use whenever running openspec propose, opsx:propose, openspec-propose, openspec continue/ff, writing a design.md, or running openspec apply / opsx:apply / openspec-apply-change, and whenever reviewing code produced by an OpenSpec change.
---

# OpenSpec Code Practices Gate

Run this gate **before** drafting `design.md` or `tasks.md`, and **before** writing any code during `apply`. Its job: make sure the design and the implementation follow the installed best-practice skills instead of training-data defaults.

## Practice skills

All live in `~/.agents/skills/<name>/` (a project may also have a copy in `.agents/skills/<name>/` or `.claude/skills/<name>/` — prefer the project copy if present, it is the version locked in that project's `skills-lock.json`).

| Skill | Applies when the project / change touches |
|---|---|
| `next-best-practices` | `next` in package.json — routing, RSC, data fetching, metadata, images, fonts. Discontinued upstream, so `node_modules/next/dist/docs/` wins wherever the two differ |
| `vercel-react-best-practices` | Any React or Next.js code (performance, waterfalls, bundle, re-renders) |
| `vercel-composition-patterns` | Designing or refactoring React component APIs, context, providers |
| `vercel-react-view-transitions` | Animations, page/route transitions, enter/exit, shared elements |
| `vercel-react-native-skills` | `react-native` or `expo` in package.json |
| `material-ui-styling` | `@mui/material` — any styling change (`sx`, `styled`, theme overrides) |
| `material-ui-theming` | `@mui/material` — theme, tokens, palette, dark mode, CSS variables |
| `material-ui-nextjs` | `@mui/material` + `next` — providers, cache, fonts, Link, SSR |
| `material-ui-tailwind` | `@mui/material` + `tailwindcss` |
| `web-design-guidelines` | Any web UI — accessibility / UX review of the produced UI |
| `tauri-best-practices` | `src-tauri/` folder or `@tauri-apps/api` in package.json |
| `desktop-app-best-practices` | Any desktop app — windows, installers, updates, app data |
| `frontend-design` | New UI screens or visual redesigns |
| `web-artifacts-builder` | Only when the change builds a claude.ai HTML artifact |

## Procedure

1. **Detect the stack.** Read the target project's `package.json` (and the workspace package for monorepos). Note `next`, `react`, `react-native`/`expo`, `@mui/material`, `tailwindcss`, `@tauri-apps/api` and their versions. If the project has an `AGENTS.md`/`CLAUDE.md` with framework warnings (e.g. "read `node_modules/next/dist/docs/`"), follow them too. Read the project's `.agents/instructions/` (or `.agent/instructions/`), including any section that overrides a skill, the global rules in `~/.agents/instructions/`, and the `docs/` pages that cover the change.
2. **Read every practice skill index.** Read the `SKILL.md` of **all** skills in the table above (they are short indexes). Mark each as *applies* or *not applicable* using the table and the change scope.
3. **Deep-read what applies.** For each applicable skill, open the specific rule/reference files that match the change (e.g. `rules/async-parallel.md`, `rsc-boundaries.md`, MUI `AGENTS.md` sections). Read them — do not rely on the index line alone. CRITICAL/HIGH priority categories are always in scope for React/Next code.
4. **Apply to the current phase:**
   - **design.md** — add a section `## Code Practices` listing each applicable skill and the concrete rules that shape this design (e.g. "`async-parallel`: fetch user and orders with `Promise.all` in the page Server Component"). Make design decisions comply; if a decision intentionally deviates, say why.
   - **tasks.md** — where a task is governed by a rule, reference it inline (e.g. `- [ ] 2.1 Build OrderList as Server Component (next: rsc-boundaries; react: server-serialization)`). Add a final task: `Verify implementation against Code Practices in design.md`.
   - **apply** — before each task, re-check the rules referenced by that task and by `design.md ## Code Practices`. Write code that complies. After the last task, do a self-review of the changed files against those rules (and `web-design-guidelines` for UI changes) and fix violations before reporting completion.
5. **Report.** In the phase summary to the user, list the skills applied and any rule you deliberately did not follow, with the reason.

## Rules

- Skills marked *not applicable* still get their `SKILL.md` read in step 2 — skip only the deep-read.
- Project-specific instructions (`.agents/instructions/` or `.agent/instructions/`, `AGENTS.md`, `CLAUDE.md`, `openspec/config.yaml` context/rules) win over the global rules in `~/.agents/instructions/`, and both win over generic skill advice when they conflict; mention the conflict.
- Do not paste skill content into artifacts — cite rule names and state the concrete decision.
- This gate never relaxes OpenSpec's own guardrails (planning boundary in propose, task-by-task flow in apply).
