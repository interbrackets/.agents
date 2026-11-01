# Testing Tauri Apps

## Frontend tests with mocks

`@tauri-apps/api/mocks` fakes the IPC layer, so component and hook tests run without Rust.

```ts
import { afterEach, beforeAll, expect, test, vi } from 'vitest';
import { randomFillSync } from 'crypto';
import { clearMocks, mockIPC } from '@tauri-apps/api/mocks';
import { invoke } from '@tauri-apps/api/core';

// jsdom has no WebCrypto
beforeAll(() => {
  Object.defineProperty(window, 'crypto', {
    value: { getRandomValues: (buffer) => randomFillSync(buffer) },
  });
});

afterEach(() => clearMocks());

test('adds two numbers', async () => {
  mockIPC((cmd, args) => {
    if (cmd === 'add') return (args.a as number) + (args.b as number);
  });

  const spy = vi.spyOn(window.__TAURI_INTERNALS__, 'invoke');

  await expect(invoke('add', { a: 12, b: 15 })).resolves.toBe(27);
  expect(spy).toHaveBeenCalled();
});
```

- Call `clearMocks()` after each test, or mock state leaks between tests.
- `mockIPC` makes `window.__TAURI_INTERNALS__` exist, so an `isDesktop()` guard returns `true`. Test the browser fallback separately, without the mock.

## Rust tests

Write commands with `<R: Runtime>` so tests can use Tauri's mock runtime:

```rust
#[tauri::command]
async fn my_command<R: tauri::Runtime>(app: tauri::AppHandle<R>) {}
```

Keep logic in plain functions that a command calls, so most Rust tests need no Tauri runtime at all.

## End-to-end tests

The recommended route is **WebdriverIO with `@wdio/tauri-service`**, which works on Windows, Linux, and macOS.

```shell
npm create wdio@latest ./
```

Choose Desktop Testing, then Tauri.

```ts
export const config: WebdriverIO.Config = {
  services: [['tauri', {
    appBinaryPath: './src-tauri/target/release/my-tauri-app',
    driverProvider: 'embedded',
  }]],
};
```

| Option | What it does |
|---|---|
| `embedded` provider (default) | WebDriver server inside the app through `tauri-plugin-wdio-webdriver`. No external driver, and how macOS is supported |
| `external` provider | Native WebDriver through `tauri-driver`, on Windows and Linux |
| `crabnebula` provider | Cross-platform `tauri-driver` fork. macOS needs a paid key |
| `tauri-plugin-wdio` | Adds `browser.tauri.execute()`, command mocking, and log capture |
| Browser mode | Runs the frontend in Chrome with mocked `invoke()`. No Tauri binary needed |

Keep test-only plugins out of release builds.

## What each layer proves

| Layer | Proves | Misses |
|---|---|---|
| `mockIPC` unit tests | Frontend logic and error handling | Real permissions, real Rust |
| Rust tests | Command logic | Whether the frontend can call it |
| End-to-end on a real build | Capabilities, CSP, and the full flow | Slow, so reserve for key paths |

A missing permission or a CSP block appears only on a real build, so run at least one end-to-end pass on a packaged app before release.
