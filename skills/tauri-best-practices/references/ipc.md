# Tauri IPC and Rust State

## Choosing a mechanism

| Need | Use | Why |
|---|---|---|
| Call Rust and get a result | **Command** | Type safe, returns a value or error, supports capabilities |
| Stream data or progress | **Channel** | Fast and ordered. Used internally for downloads and child process output |
| Small notification to many listeners | **Event** | Simple multi-consumer broadcast. Not for low latency or high throughput |
| Large binary response | **Command** returning `tauri::ipc::Response` | Skips JSON serialization |

Events are not type safe, cannot return values, and carry JSON only. They evaluate JavaScript under the hood, so they do not suit large payloads.

## Commands

```rust
#[tauri::command]
async fn read_config(path: String) -> Result<Config, Error> {
    // ...
}

pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![read_config, save_config])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

- **One `generate_handler!` call.** Calling `invoke_handler` twice keeps only the last call.
- **Names are global.** Command names must be unique, even across modules.
- **`pub` depends on location.** Commands in `lib.rs` cannot be `pub`, which causes error `E0255`. Commands in a separate module must be `pub`, and you register them as `commands::name`.
- **Arguments are camelCase in JS.** Rust `invoke_message` becomes `{ invokeMessage }` unless you set `rename_all = "snake_case"`.
- Arguments implement `Deserialize`, and return values and errors implement `Serialize`.
- `AppHandle`, `WebviewWindow`, and `State` are injected and are not sent from JS.
- To test with the mock runtime, write `<R: Runtime>` on the command's generic parameters.

## Threads and async

Commands without `async` run on the **main thread**, unless declared with `#[tauri::command(async)]`. Any slow work there freezes the window, so declare commands `async` by default.

Async commands cannot take borrowed arguments directly. There are two fixes:

```rust
// Option 1: use an owned type instead of &str
#[tauri::command]
async fn one(value: String) -> String { value }

// Option 2: return a Result. Required for State<'_, T>
#[tauri::command]
async fn two(state: tauri::State<'_, Db>) -> Result<u32, ()> { Ok(0) }
```

## Errors

Returning `Err` rejects the `invoke` promise. A `String` error works for small cases, but a typed enum lets the frontend branch on the failure.

```rust
#[derive(Debug, thiserror::Error)]
enum Error {
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error("failed to parse as string: {0}")]
    Utf8(#[from] std::str::Utf8Error),
}

#[derive(serde::Serialize)]
#[serde(tag = "kind", content = "message")]
#[serde(rename_all = "camelCase")]
enum ErrorKind {
    Io(String),
    Utf8(String),
}

impl serde::Serialize for Error {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        let message = self.to_string();
        let kind = match self {
            Self::Io(_) => ErrorKind::Io(message),
            Self::Utf8(_) => ErrorKind::Utf8(message),
        };
        kind.serialize(serializer)
    }
}
```

```ts
type TErrorKind = { kind: 'io' | 'utf8'; message: string };
invoke('read').catch((e: TErrorKind) => {});
```

## Channels

```rust
use tauri::ipc::Channel;

#[derive(Clone, serde::Serialize)]
#[serde(rename_all = "camelCase", rename_all_fields = "camelCase", tag = "event", content = "data")]
enum DownloadEvent {
    Started { download_id: usize },
    Progress { download_id: usize, chunk_length: usize },
    Finished { download_id: usize },
}

#[tauri::command]
fn download(on_event: Channel<DownloadEvent>) {
    on_event.send(DownloadEvent::Started { download_id: 1 }).unwrap();
}
```

```ts
import { Channel, invoke } from '@tauri-apps/api/core';

const onEvent = new Channel<TDownloadEvent>();
onEvent.onmessage = (message) => {};
await invoke('download', { onEvent });
```

## Events

- `emit` reaches all listeners, and `emit_to` reaches one webview by label.
- Webview-specific events do **not** reach regular global listeners. Use `{ target: { kind: 'Any' } }` in JS or `listen_any` in Rust to catch everything.
- Event payloads need `Serialize` and `Clone`.
- Call the unlisten function on cleanup so listeners do not pile up across renders.

## Managed state

```rust
use std::sync::Mutex;

#[derive(Default)]
struct AppState { counter: u32 }

// in setup: app.manage(Mutex::new(AppState::default()));

#[tauri::command]
fn increase(state: tauri::State<'_, Mutex<AppState>>) -> u32 {
    let mut state = state.lock().unwrap();
    state.counter += 1;
    state.counter
}
```

- **No `Arc` needed.** `State` already shares ownership.
- **The standard `Mutex` is usually right**, even in async code. Reach for Tokio's `Mutex` only when you hold the guard across an `.await`, such as around a database connection.
- **The type must match exactly, and the compiler will not catch it.** `State<'_, AppState>` when you managed `Mutex<AppState>` fails at runtime: `invoke` rejects with `state not managed for field ...`, and `Manager::state()` panics. A type alias prevents this.
- **Outside commands**, clone an `AppHandle`, which is cheap, and call `handle.state::<T>()`.
