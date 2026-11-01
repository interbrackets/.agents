# Install and Update

## Installation

- Support per-user install. It avoids UAC prompts and makes installing easier.
- Do not require admin rights to install or to run. If one feature truly needs elevation, put it in a separate process to reduce the attack surface.
- Avoid requiring a reboot, and do not install or update system binaries.
- Leave no temporary files behind.
- Support silent install for enterprise deployment.
- Register in Settings > Apps > Installed apps.

## Signing

Sign everything executable: EXE, DLL, installer, and uninstaller. Without MSIX there is no package signature, so individual binary signatures are what Smart App Control and enterprise policies check.

New certificates may show a SmartScreen warning at first, until reputation builds.

## Uninstall

- Provide an uninstall through Installed apps.
- Remove binaries, Start menu entries, directories, registry entries, and temporary files.
- Keep user-created content in locations like `Documents`, so it outlives the app.
- Consider offering to keep user data at uninstall time.

## Updates

- Let users restart when it suits them. Never close the app mid-work.
- Save state before installing, and restore it after.
- Download only the changed parts where the mechanism allows it.
- Check at startup, at restart, or by push, rather than constant polling.
- Provide a way to repair an app as well as update it.
- Migrate stored data between versions, and test upgrades from old versions, not only clean installs.
- Sign updates and fetch them over TLS.
- Plan a rollback. Know what happens if a release is bad.

## Multiple instances

Decide on purpose whether a second launch opens a new window or focuses the existing one. Most single-document apps should focus the existing window. Deep links and file associations usually arrive as a new process, so they must be forwarded to the running one.

## Distribution

- If you ship through several channels, keep one app identity and update path across them.
- List the app in the Microsoft Store or the WinGet repository so it is easy to find and install.
- Consider MSIX for clean install, update, and removal. It handles repair and data removal automatically, but changes how files and registry entries work.

## Windows on Arm

Windows 11 runs many x64 apps under Prism emulation, but native ARM64 builds perform best. If you ship emulated, test on real Arm hardware.
