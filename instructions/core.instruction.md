# Core Rules — Global

**Version:** 1.0 | **Purpose:** Conventions for every project. Other global files build on this one.

**Precedence.** These rules fill gaps. A project's `.agents/instructions/` (or `.agent/instructions/`),
`AGENTS.md`, `CLAUDE.md` and `openspec/config.yaml` win wherever they differ.

| File | Applies to |
|---|---|
| `core.instruction.md` | Every project |
| `frontend.instruction.md` | React UI |
| `api.instruction.md` | Client code that talks to an API |
| `desktop.instruction.md` | Desktop apps |
| `review.instruction.md` | Every code review |

---

## CODE

- Arrow functions only — components, hooks, helpers, callbacks. Never `function` declarations
- `any` is **forbidden** — define a specific interface or type
- Derive values instead of storing them; state holds the minimum truth
- Empty `catch` blocks are forbidden; throw a descriptive `Error` or handle the failure
- Allowed logging: `console.error` in catch blocks. No `console.log` in committed code
- No commented-out code unless marked `// TODO: [change-name]`

---

## NAMING (TypeScript)

### Prefix System

| Prefix | Target | Example |
|---|---|---|
| `I` | Interfaces | `IUserCard`, `IApiError` |
| `T` | Type aliases | `TThemeMode`, `TLanguage` |
| `S` | Styled components | `SContainer`, `SButton` |
| `use` | Hooks | `useUserData` |
| `get`, `post`, `put`, `delete` | Query functions | `getUserData`, `putUserData` |

### Files and Folders

| Target | Convention | Example |
|---|---|---|
| Component folders | PascalCase | `UserCard/` |
| Hook folders | PascalCase, `Use` prefix | `UseUserData/` |
| Config, utility, type files | camelCase | `queryClient.ts`, `strings.ts` |
| Route folders | kebab-case | `forgot-password/` |
| Language files | ISO 639-1 | `en.json` |

### In Code

```typescript
const userData = {};            // variables: camelCase
const MAX_RETRIES = 3;          // constants: UPPER_SNAKE_CASE
const UserProfile = () => {};   // components: PascalCase

// Event handlers: on + Verb — never onCallback, onAction, onClick (too generic)
onClose, onSubmit, onDelete, onConfirm, onSelect, onItemClick

// JSON fields exchanged with an API: camelCase only
```

---

## FOLDER STRUCTURE (default for a TypeScript UI)

```
src/
├── app/            # Routes
├── components/     # Reusable UI — PascalCase folders
├── config/         # Plugin init: axios, queryClient, i18n, theme, routes
├── context/        # Shared contexts
├── hooks/          # Custom hooks — PascalCase folders, Use prefix
├── types/          # Shared types, interfaces, validation schemas
├── utils/          # Pure utilities — camelCase files
├── language/       # i18n JSON
└── _tests/         # Unit tests — mirrors src
```

**Forbidden:**
- `lib/` anywhere — use `utils/`
- Component files outside a PascalCase folder (e.g. `src/components/Button.tsx`)
- Hook files outside `src/hooks/UseName/` — **exception:** a hook owned by a provider component is
  exported from that provider's `index.tsx`

---

## TYPE SYSTEM

1. Component and hook props: `interface` with `I` prefix
2. Unions, primitives, function signatures: `type` with `T` prefix
3. Component- or hook-specific types: inline in its `index.tsx`
4. Types shared across child components: `types.ts` within the folder
5. App-wide types and Zod schemas: `src/types/`

---

## STATE MANAGEMENT

```
Is state from the API?
  YES → TanStack Query (queryFns.ts)
  NO  → Is it user identity, theme, or language?
          YES → App-wide context
          NO  → useState (component-local)
Must it survive a restart or reload?
  YES → localStorage (versioned key) — never sessionStorage
```

**Forbidden:** API data in `useState` + `useEffect`; user, theme or language in `useState`; prop
drilling through 3+ levels.

---

## SECURITY

- Values in client-exposed variables (`NEXT_PUBLIC_*` and similar) ship to every user. Public
  configuration only, never a secret
- Never put a token in a URL query string; never log tokens
- Validation on a client is a UX layer. Anything that must be enforced is enforced by the backend
- All token handling sits behind one module. Nothing above it calls an auth SDK
- `.safeParse()` anything parsed from a deep link, a query string, or browser storage

---

## TESTING

- Tests live in `src/_tests/`, mirroring `src/`
- Red, green, refactor — a task is not complete until its tests pass
- Report what was actually run. A check that was skipped is stated, never implied
