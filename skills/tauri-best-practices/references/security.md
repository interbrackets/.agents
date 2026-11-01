# Tauri Security

## What the security layers cover

Capabilities and permissions reduce the damage from a compromised frontend. They do **not** protect against:

- Malicious or insecure Rust code
- Scopes that are too broad
- Incorrect scope checks inside a command
- 0-days or unpatched bugs in the system webview
- Supply chain attacks or a compromised developer machine

So a tight capability file does not excuse a command that trusts its input.

## Capabilities

Capabilities grant permissions to windows and webviews. They live in `src-tauri/capabilities/` as JSON or TOML.

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "main-capability",
  "description": "Capability for the main window",
  "windows": ["main"],
  "permissions": ["core:path:default", "core:event:default", "core:window:allow-set-title"]
}
```

- **Grant by need.** Add a permission only when code uses it, and prefer a specific `allow-*` over a broad default.
- **Files in the folder are all active.** Every capability in `capabilities/` is enabled automatically. Once `app.security.capabilities` lists any, only the listed ones are used, so a new file can silently do nothing.
- **Overlaps merge.** A window in two capabilities gets the permissions of both, so an extra capability can widen a window you thought was locked down.
- **Boundaries use window labels, not titles.** Expose window creation only to higher-privileged windows.
- **Split by platform** with `"platforms": ["linux", "macOS", "windows"]` so mobile-only and desktop-only plugins do not collide.
- **Use the schema.** `$schema` points to `gen/schemas/`, which gives you autocomplete of real permission names.

### Your own commands

All commands registered with `invoke_handler` are allowed for **all** windows by default. To change that, declare them in `build.rs` so they go through the permission system:

```rust
fn main() {
    tauri_build::try_build(
        tauri_build::Attributes::new()
            .app_manifest(tauri_build::AppManifest::new().commands(&["your_command"])),
    )
    .unwrap();
}
```

### Remote content

By default the API is available only to bundled code. `remote.urls` opens commands to remote origins. Use it sparingly: on Linux and Android, Tauri cannot distinguish an embedded `<iframe>` from the window itself.

### Events are not covered

The event system has no capability support. Any code in the webview can emit and listen, so never let an event trigger a privileged action on its own. Use a command, which can be permissioned.

## Permissions and scopes

- Plugins block potentially dangerous commands and scopes by default, so each plugin needs explicit permissions.
- Identifier format is `<plugin>:<name>`, and `<plugin>:default` is the plugin's default set.
- **`deny` always wins over `allow`.**
- **A scope is enforced by the command itself.** Tauri passes the scope in; it does not check it for you. Custom scoped commands must be audited for bypasses.
- Keep paths inside a base directory such as `$APPDATA`. Do not grant access to the whole home folder.
- On Windows, keep `$APPLOCALDATA/EBWebView` denied. It holds webview data and configuration, and reading it can expose sensitive information.

```json
{
  "identifier": "opener:allow-open-url",
  "allow": [{ "url": "https://example.com/*" }]
}
```

## Content Security Policy

CSP is enabled **only if set** in `tauri.conf.json`. Tauri adds nonces and hashes for bundled code at compile time, so you only list what is unique to your app.

```json
"csp": {
  "default-src": "'self' customprotocol: asset:",
  "connect-src": "ipc: http://ipc.localhost https://api.example.com",
  "img-src": "'self' asset: http://asset.localhost blob: data:",
  "style-src": "'self' 'unsafe-inline'"
}
```

- Allow only hosts you trust and preferably own.
- Avoid loading scripts from a CDN. It adds an attack vector the app cannot verify.
- Never allow `'unsafe-inline'` in `script-src`.
- Add `'wasm-unsafe-eval'` to `script-src` only if the frontend uses WebAssembly.
- CSS-in-JS libraries such as Emotion, used by Material UI, inject styles at runtime and need `'unsafe-inline'` in `style-src`. Tauri's injected style nonce makes browsers ignore `'unsafe-inline'`, so also set `app.security.dangerousDisableAssetCspModification` to `["style-src"]`. Limit it to that one directive.

## Isolation pattern

The Isolation pattern runs a small sandboxed app between the frontend and Tauri Core. It intercepts **all** IPC messages, including events, so you can validate them before they reach Rust. Its main target is threats from the frontend's dependency tree, and Tauri recommends it whenever it can be used.

```json
{
  "build": { "frontendDist": "../dist" },
  "app": {
    "security": {
      "pattern": { "use": "isolation", "options": { "dir": "../dist-isolation" } }
    }
  }
}
```

```javascript
// ../dist-isolation/index.js
window.__TAURI_ISOLATION_HOOK__ = (payload) => payload; // validate here
```

- Keep the isolation app minimal, with few dependencies and few build steps. Otherwise it inherits the same supply chain risk.
- ES Modules do **not** load inside the sandboxed iframe on Windows. Use a plain `<script src="index.js">`.
- Expect a small cost from AES-GCM on each message. Most apps will not notice it.

## Lifecycle threats

- Keep `tauri`, `rustc`, and Node current. Your installer ships Tauri itself.
- Run `cargo audit` and `npm audit`, or the `pnpm` equivalent. Pin critical dependencies by hash or tag.
- Pin third-party CI actions to explicit versions.
- The dev server has no encryption or authentication and is exposed to the local network. Develop on trusted networks only.
- Keep production secrets off development machines and out of source control.
- Sign binaries for each platform you ship to.
- Offer a clear way to report vulnerabilities.
