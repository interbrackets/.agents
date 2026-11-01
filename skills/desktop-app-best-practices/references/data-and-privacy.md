# Data and Privacy

## Where data goes on Windows

| Data | Location | Known folder |
|---|---|---|
| User-created documents | `Documents`, or a folder the user picks | `FOLDERID_Documents` |
| Settings that follow the user | `%APPDATA%` (`AppData\Roaming`) | `FOLDERID_RoamingAppData` |
| Machine-specific data and caches | `%LOCALAPPDATA%` (`AppData\Local`) | `FOLDERID_LocalAppData` |
| Data shared by all users | `%PROGRAMDATA%` | `FOLDERID_ProgramData` |
| Program binaries | Install folder | `FOLDERID_ProgramFiles`, or `%LOCALAPPDATA%` for per-user |

- Resolve these with the OS or framework API. Never hardcode a drive or username.
- Do not write to the install folder at runtime. A standard user cannot under Program Files, and updates replace it.
- Keep large caches out of Roaming, because it can travel with the user's profile.
- Make caches disposable, so that deleting them never loses user data.

## Credentials and secrets

- Keep credentials in a platform or service credential store. On Windows that is Credential Manager.
- Do not embed secrets in source, config files, logs, or client binaries. Anything shipped in the installer can be extracted.
- Anything that must stay secret belongs on a backend.
- Use standard libraries for cryptography. Do not build your own.
- Keep tokens out of URLs and logs.

## Stored data

- Version persisted data, and migrate it on upgrade.
- Parse stored values defensively. Users, sync tools, and crashes can corrupt files, so fall back to defaults rather than failing to start.
- Write important files atomically: write to a temporary file, then rename it, so a crash cannot leave half a file.

## Network

- Use TLS for all network traffic.
- Validate data from the network and from deep links, files, and arguments. These all cross a trust boundary.

## Logging

- Log to a per-user location with rotation, so logs cannot fill the disk.
- Never log tokens, passwords, or personal data.
- Give users a simple way to find logs for support.

## Privacy

- Collect the least personal data the feature needs. Do not collect "just in case".
- Get consent before collecting personal data, and make it easy to change that decision later.
- Do not use dark patterns such as making "Yes" more prominent than "No".
- Provide an accurate privacy policy, covering what is collected, how it is used and stored, who receives it, and what control users have.
- Keep the policy current as features change.
- Check that third-party SDKs also respect privacy. Any library that connects to the internet can affect your users.
- Follow the rules of each market you ship in, including deletion requests.
- Crash reporting and telemetry are data collection. Make them opt-in, or clearly disclosed with an off switch.
