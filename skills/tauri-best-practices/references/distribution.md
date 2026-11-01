# Tauri Distribution

## Windows installers

Tauri builds NSIS (`-setup.exe`) and WiX (`.msi`) installers.

### WebView2 install mode

Set with `bundle.windows.webviewInstallMode.type`.

| Mode | Needs internet | Installer size added | Use for |
|---|---|---|---|
| `downloadBootstrapper` | Yes | 0 MB | **Default.** Most apps |
| `embedBootstrapper` | Yes | ~1.8 MB | Better Windows 7 support with `.msi` |
| `offlineInstaller` | No | ~127 MB | Offline environments |
| `fixedRuntime` | No | ~180 MB | You must control the WebView2 version |
| `skip` | — | 0 MB | Runtime is guaranteed to be present |

Prefer the system runtime. Windows then patches webview vulnerabilities for you, while a fixed runtime makes each security patch your job.

If the app needs newer webview features, set `bundle.windows.minimumWebview2Version` so the installer can upgrade the runtime.

### Install mode (NSIS)

| `installMode` | Location | Needs admin |
|---|---|---|
| `currentUser` (default) | `%LOCALAPPDATA%` | No |
| `perMachine` | `C:/Program Files` | Yes |
| `both` | User's choice | Yes |

Stay with `currentUser` unless the app must be system-wide. It avoids UAC prompts, matching Microsoft's guidance.

### Architectures

The CLI builds for the host architecture. Add `--target` for others, such as `aarch64-pc-windows-msvc` or `i686-pc-windows-msvc`.

## Code signing (Windows)

Signing is not needed for the app to run, but it is needed for the Microsoft Store and to avoid the SmartScreen warning on browser downloads.

- **EV no longer skips SmartScreen.** Since 2024, EV and OV certificates build reputation the same way, and a newly signed release can warn with either. Older advice saying EV gives instant trust is out of date.
- **Keep the same certificate** across releases so reputation carries over. You can also submit the app to Microsoft for manual review.
- **Check which guide applies.** The `certificateThumbprint` flow only covers OV certificates issued before June 1, 2023. For newer certificates, follow your issuer's docs and use `bundle.windows.signCommand`.
- **Prefer a cloud or hardware key.** Azure Key Vault works through `signCommand`, for example with `relic`:

```json
{ "bundle": { "windows": { "signCommand": "relic sign --file %1 --key azure --config relic.conf" } } }
```

## Updater

Signature checks **cannot be disabled**.

```shell
pnpm tauri signer generate -w ~/.tauri/myapp.key
```

```json
{
  "bundle": { "createUpdaterArtifacts": true },
  "plugins": {
    "updater": {
      "pubkey": "CONTENT OF THE PUBLIC KEY",
      "endpoints": ["https://releases.myapp.com/{{target}}/{{arch}}/{{current_version}}"]
    }
  }
}
```

- **Back up the private key now.** If it is lost, apps already installed can never receive another update. Never share or commit it.
- Provide it at build time through `TAURI_SIGNING_PRIVATE_KEY` and `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`. A `.env` file does not count.
- `pubkey` holds the key's **content**, not a file path.
- Endpoints need TLS in production. Leave `dangerousInsecureTransportProtocol` off.
- Tauri moves to the next endpoint only on a non-2XX status.
- A dynamic update server responds `204 No Content` when no update is available.
- `version` in the response must be valid SemVer, and `pub_date` must be RFC 3339.

### On Windows

Tauri automatically quits the app before installing, because of a limitation in Windows installers. Save state first with `on_before_exit`.

`installMode` under `plugins.updater.windows`:

| Mode | Behavior |
|---|---|
| `passive` | **Default and recommended.** Small progress window, no interaction |
| `basicUi` | Requires user interaction |
| `quiet` | No feedback. Cannot request admin rights. Not recommended |

## Single instance

The plugin **must be registered first** so nothing runs before it. By default a second launch does nothing visible, so focus the existing window:

```rust
tauri::Builder::default()
    .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
        let _ = app.get_webview_window("main").expect("no main window").set_focus();
    }))
```

## Deep links

On Windows and Linux a deep link arrives as a **command line argument to a new process**, so it needs `single-instance` to reach the running app.

```toml
tauri-plugin-single-instance = { version = "2.0.0", features = ["deep-link"] }
```

Keep it the first plugin. Schemes registered at runtime are not forwarded automatically, so check `argv` for them yourself.

Treat the URL as untrusted input: parse and validate it before acting on it.

## Sidecars

List binaries in `bundle.externalBin`. Each path needs a build named with the `-$TARGET_TRIPLE` suffix, for example `binaries/my-sidecar-x86_64-pc-windows-msvc.exe`. Get the triple with `rustc --print host-tuple` (Rust 1.84+).

Running a sidecar needs a shell plugin permission, scoped to that binary and its arguments.

## Persistence plugins

- `window-state` restores window size and position across restarts.
- `store` persists JSON key-value data. Use `LazyStore` to load on first access, and call `save()` when `autoSave` is off.
- `store` is plain files, so never put secrets in it. Use a platform credential store, or `stronghold`, which needs a password-derived key from the app.
