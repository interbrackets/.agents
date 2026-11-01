# Code Review Rules — Global

**Version:** 1.0 | **Purpose:** Architecture enforcement, duplication detection and security review.
**Conventions:** see `core.instruction.md`. A project's own review file wins and may list
grandfathered code; a hit on a grandfathered line is reported, not blocking.

Run the signal; a hit is a finding.

---

## ARCHITECTURE VIOLATIONS

| Violation | Signal | Required Fix |
|---|---|---|
| API data in `useState` + `useEffect` | `.then(r => setState(...))`, `useEffect` calling the client or `fetch` | TanStack Query via `queryFns.ts` |
| Raw axios or SWR in a component or hook | `import axios from 'axios'`, `from 'swr'` in `src/components/` or `src/hooks/` | The configured client; TanStack Query |
| Inline `queryFn` or API call in a component | `queryFn: async () =>` inside `index.tsx` | Extract to `queryFns.ts` |
| Auth SDK above the auth module | SDK imports or token parsing outside it | Call the module; consume identity from context |
| `function` declaration | `function Name(`, `export default function`, `async function` | Arrow function |
| `forwardRef` | `forwardRef(` | `ref` as a plain prop (React 19) |
| `useContext` | regex `useContext\(` | `use(Context)` |
| Global state in `useState` | `useState` holding user, theme or language | App-wide context |
| Prop drilling | Same prop through 3+ levels | Context or composition |
| Styles in `index.tsx` | `styled(` or `style={{` in a component file | Move to `styles.ts` |
| MUI root-barrel import | regex `from ["']@mui/(material\|icons-material)["']` — `import type` is a style finding only | Subpath import |
| `&&` conditional JSX | regex `&& *[(<]` | Ternary `{cond ? <…/> : null}` |
| Component inside component | `const Inner = () =>` inside a component body | Hoist or extract a file |
| `useSearchParams` without Suspense | `useSearchParams()` not under `<Suspense>` | Wrap the consumer |
| Hydration-unsafe read | `window.`, `matchMedia(`, `localStorage.`, `navigator.` in render or a `useState` initialiser | Read in `useEffect`; neutral first frame |
| `sessionStorage` for persistence | `sessionStorage.setItem(` of a setting | `localStorage` with a versioned key |
| Inconsistent `queryKey` | Same resource with different key arrays | Single shared key constant |
| Mutation without invalidation | `useMutation` without `invalidateQueries` in `onSuccess` | Add `invalidateQueries` |
| Secret in the bundle | `NEXT_PUBLIC_*SECRET*`, `*KEY*`, `*TOKEN*` | Move to the backend |

Desktop projects also apply the signals in `desktop.instruction.md`.

---

## DUPLICATE CODE

Flag for extraction if the same logic exists in 2+ places:

- Same HTTP call in 2+ `queryFns.ts` → shared util
- Same Zod schema in 2+ `types.ts` → `src/types/`
- Same styled component in 2+ `styles.ts` → shared component
- Same `queryKey` array in 2+ places → shared constant
- Same runtime guard copied around → one helper in `src/config/`

---

## NAMING AND STRUCTURE

Fail review if:

- `any` used
- Interface without `I` prefix; type alias without `T` prefix; styled component without `S` prefix
- Hook not starting with `use`; hook folder not `UseName/`; component folder not PascalCase
- Event-handler prop not starting with `on` (`handleClick` as a prop name)
- snake_case or PascalCase JSON fields exchanged with the API
- `lib/` used instead of `utils/`
- Component is a flat file (`src/components/Button.tsx`)
- `queryFns.ts` missing when `useQuery`/`useMutation` is used; `styles.ts` missing when `styled(` is used

---

## ANTI-PATTERNS

- [ ] No conditional hook calls; no hooks in loops
- [ ] No callback prop defaults (`onClose = () => {}`)
- [ ] No inline object or array literals as props in list renders
- [ ] No custom `useForm` — use `react-hook-form`
- [ ] No `eval()` or dynamic `require()`; no `dangerouslySetInnerHTML` with remote content

---

## DEAD CODE

- Unused imports; exports never imported; interfaces in `types.ts` not used
- Commented-out code (unless `// TODO: [change-name]`)
- `console.log` — allowed: `console.error` in catch blocks only
- Empty `queryFns.ts` or `types.ts`
- Env vars referenced in code but undocumented, or the reverse

---

## SECURITY

- [ ] Token handling is confined to the auth module; one place sets the bearer header
- [ ] No token in a URL query string; no token logged
- [ ] No secret in a client-exposed variable
- [ ] Every protected route is guarded
- [ ] 401 handling refreshes once, then signs out; the HTTP module never navigates
- [ ] `.safeParse()` on anything parsed from a deep link, a query string, or browser storage

---

## PERFORMANCE (flag, not an automatic block)

- Missing `key` on list items; inline anonymous handler inside a list map
- `useEffect` with no dependency array
- Component file over 200 lines — decompose
- Third-party barrel import — subpath or `optimizePackageImports`
- `useMemo` or `useCallback` wrapping trivial primitives — remove

---

## INCOMPLETE IMPLEMENTATION

- `queryFns.ts` function with an empty body or `throw new Error('TODO')`
- Component returning `null` with no explanatory comment
- `// @ts-ignore` without explanation
- Empty `catch`
- Mutation `onSuccess` that does nothing
- A task ticked in `tasks.md` for a verification that was not actually run
