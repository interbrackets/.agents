# Frontend Rules — Global

**Version:** 1.0 | **Scope:** React UI. Material UI sections apply when the project uses `@mui/material`.
**Conventions:** naming, types and state → see `core.instruction.md`.

---

## COMPONENTS

### File Structure

```
src/components/ComponentName/
├── index.tsx     ← component code only (no styles, no API calls)
├── styles.ts     ← all styled components
├── types.ts      ← types and schemas shared by child components
└── queryFns.ts   ← required if the component uses useQuery/useMutation
```

Complex components nest `SubComponent/` folders with the same files.

### Template

```tsx
'use client';

/** Types && Interfaces */
export interface IMyComponent {
  title: string;
  variant?: 'primary' | 'secondary';
  onClose?: () => void;            // callbacks: optional, never with defaults
  ref?: React.Ref<HTMLDivElement>; // React 19: ref is a plain prop — no forwardRef
  children?: React.ReactNode;
}

/** Component */
const MyComponent: React.FC<IMyComponent> = ({
  title,
  variant = 'primary',             // defaults in the signature, not the body
  onClose,
  ref,
  children = null,
}) => {
  return (
    <SContainer ref={ref} $variant={variant}>
      <STitle>{title}</STitle>
      {children}
      {onClose ? <SCloseButton onClick={() => onClose()}>Close</SCloseButton> : null}
    </SContainer>
  );
};

export default MyComponent;
```

### Mandatory Rules

- Components: `const Name: React.FC<IProps> = () => {}`; both named interface export and default export
- Section comments: `/** Types && Interfaces */` and `/** Component */`
- No styles and no API calls in `index.tsx`
- Callbacks: optional (`?`), never defaulted (`= null`, `= () => {}`), invoked with `?.()` or guarded
- **Conditional JSX uses ternaries** (`cond ? <X/> : null`), never `cond && <X/>` — `0` and `''` render
- **No component defined inside another component's body** — hoist it or extract a file
- **Expensive initial state uses a lazy initialiser** (`useState(() => compute())`)
- **Prefer composition over boolean modes.** A component that needs `isCompact`, `isInline`,
  `showHeader` is three components or a `variant` prop — not three booleans
- **No `forwardRef`** — accept `ref` as a prop (React 19)

---

## HYDRATION AND PERSISTENCE

When HTML is prerendered, `window` is undefined and the first client render **must produce the same
tree**.

- Never read `window`, `matchMedia`, `localStorage` or `navigator` in render or in a `useState`
  initialiser when the result can differ from the prerender. Read it in `useEffect` and update
  state, or render a neutral first frame
- Persistent preferences live in `localStorage` under versioned, minimal keys (`app.v1.theme`),
  accessed through a helper in `src/config/` — never `sessionStorage`
- Parse stored values defensively; a missing or malformed key falls back to the default

---

## STYLING (Material UI)

Decision order — narrowest scope first:

1. **`sx`** — one-off, local tweak using theme tokens
2. **`styled()` in `styles.ts`** — reusable element or anything with dynamic props
3. **`createTheme({ components })`** — every instance of an MUI component
4. **Global CSS** — resets and the `@layer` declaration only

```tsx
// Dynamic props → styled() with $-prefixed transient props
export const SButton = styled('button', {
  shouldForwardProp: (prop) => prop !== '$variant',
})<{ $variant?: 'primary' | 'secondary' }>(({ theme, $variant }) => ({
  backgroundColor: $variant === 'primary' ? theme.palette.primary.main : theme.palette.grey[300],
  padding: theme.spacing(1, 2),
}));
```

- All styled components: `S` prefix; transient props: `$` prefix + `shouldForwardProp`
- Theme tokens over hardcoded values
- Never inline `style={{ … }}`; never define styled components in `index.tsx`
- **MUI imports use subpaths**: `import Button from '@mui/material/Button'` — never
  `import { Button } from '@mui/material'`
- With Tailwind: `@layer theme, base, mui, components, utilities;` comes **before**
  `@import "tailwindcss";`, and `AppRouterCacheProvider` sets `enableCssLayer: true`
- The `@mui/material-nextjs/vNN-appRouter` import suffix follows the Next.js major
- Pass `next/link` as an MUI `component` prop only from a client component

---

## HOOKS

```
src/hooks/UseHookName/
├── index.tsx     ← hook implementation only
└── queryFns.ts   ← required if the hook uses useQuery/useMutation
```

```tsx
/** Types && Interfaces */
export interface IUseMyHookOptions { initialValue?: boolean; }
export interface IUseMyHookReturn { isOpen: boolean; open: () => void; close: () => void; }

/** Hook */
export const useMyHook = (options: IUseMyHookOptions = {}): IUseMyHookReturn => {
  const { initialValue = false } = options;
  const [isOpen, setIsOpen] = useState(initialValue);
  return { isOpen, open: () => setIsOpen(true), close: () => setIsOpen(false) };
};

export default useMyHook;
```

- Return type interface required (`IUseHookNameReturn`); options interface if parameters
- Both named and default export; section comments `/** Types && Interfaces */` and `/** Hook */`
- Context hooks use `use(Context)` and throw outside their provider
- `useEffect` dependency arrays complete; cleanup returned for subscriptions, listeners, timers
- Never call hooks conditionally or in loops — use `enabled` on queries
- `useSearchParams()` sits under a `<Suspense>` boundary
- Derive state during render, not in an effect that copies props into state

---

## BARRELS

Internal barrels (`src/components/index.ts`, `src/hooks/index.ts`) are allowed:

```typescript
export { default as MyComponent } from './MyComponent';
export type { IMyComponent } from './MyComponent';
```

Third-party barrels are not — import MUI, icons, `ramda`, `date-fns` from subpaths.
