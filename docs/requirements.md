# AutoPF Requirements

## Current Scope

- [x] Native macOS menu bar app using Swift/AppKit.
- [x] Start and stop one SSH port forwarding tunnel at a time.
- [x] Switch between persisted remote (`-R`, default) and local (`-L`) forwarding modes from the menu bar.
- [x] Discover SSH targets from `~/.ssh/config`.
- [x] Provide a Custom SSH target option.
- [x] Edit local and remote ports, with optional sync.
- [x] Optionally show the running target name in the menu bar.
- [x] Toggle launch at login through `SMAppService`.
- [x] Show a Dock icon while Settings is open, then return to menu-bar-only mode.

## Future Ideas

- Multiple simultaneous tunnels.
- Per-target port overrides.
- Connection logs and diagnostics.
- Notarized release packaging.
