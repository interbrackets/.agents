# Data Layer Rules — Global

**Version:** 1.0 | **Scope:** Client code that talks to an API.
**Conventions:** naming, types and security → see `core.instruction.md`.

---

## HTTP CLIENT

All app calls use one configured client instance in `src/config/axios.ts`. Never import raw `axios`
in a component or hook.

- The request interceptor adds the bearer token from the auth module
- On `401` it refreshes **once** and retries; if refresh fails, it signs out through the auth module
- **The HTTP module never navigates.** It is a plain module, so `useRouter` and
  `window.location.href` do not belong there. A route guard reacts to the signed-out state

---

## HTTP CONTRACT

**Success:** direct body, no wrapper. **Error:** always `IApiError`.

```typescript
export interface IApiError { error: string; code?: string; details?: unknown; }

// ✅ GET /users/123 → 200 { "id": "123", "name": "John" }
// ❌ { "success": true, "data": { ... } }   — wrapped responses are forbidden
```

---

## QUERYFNS.TS

Every component or hook using `useQuery` or `useMutation` **must** have a `queryFns.ts`.

```typescript
import axsAppIns from '@/config/axios';
import type { IItem, ICreateItemInput } from '@/types';

/** Fetches all items. Validates the response is an array. */
export const getItems = async (): Promise<IItem[]> => {
  try {
    const { data } = await axsAppIns.get('/items');
    if (!Array.isArray(data)) throw new Error('Invalid response: expected array');
    return data;
  } catch (error) {
    throw new Error(error instanceof Error ? error.message : 'Failed to fetch items');
  }
};

/** Creates an item. Input pre-validated by React Hook Form + Zod in the component. */
export const postItem = async (input: ICreateItemInput): Promise<IItem> => {
  try {
    const { data } = await axsAppIns.post('/items', input);
    return data;
  } catch (error) {
    throw new Error(error instanceof Error ? error.message : 'Failed to create item');
  }
};
```

- `try/catch` on every function — throw a descriptive `Error`
- Validate the response shape when it is uncertain; transform data here, not in the component
- `queryFns.ts` does **not** validate input — React Hook Form + Zod does that in the component
- JSDoc on each exported function

---

## VALIDATION — ZOD + REACT HOOK FORM

Schemas live in `types.ts` next to the domain interfaces, or in `src/types/` when shared.

```typescript
export const createItemSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
});
export type ICreateItemInput = z.infer<typeof createItemSchema>;
```

```
Component form (React Hook Form + Zod resolver)   ← UX layer: fast feedback, typed input
  → mutation called only with valid data
  → queryFns.ts sends it unchanged
  → backend validates again and enforces authorization   ← the security boundary
```

---

## TANSTACK QUERY

TanStack Query is the request layer. Do not add SWR, do not fetch in `useEffect`, do not cache
server data in `useState`.

```typescript
const { data, isLoading, error } = useQuery({
  queryKey: ['items', userId],       // an array, identical for the same resource everywhere
  queryFn: () => getItemsByUser(userId),
  enabled: !!userId,                 // conditional fetch — never a conditional hook call
});

const createMutation = useMutation({
  mutationFn: postItem,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['items'] }),
});
```

- Extract keys to a shared constant when used in 2+ places
- After every mutation: `invalidateQueries` — never patch the cache by hand
- `queryClient` defaults live in `src/config/queryClient.ts`
