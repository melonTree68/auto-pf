# AutoRPF Requirements

## Finished

- Native macOS menu bar app planned as Swift/AppKit in an Xcode project.
- One active reverse SSH tunnel at a time.
- Ports default to `7890` and can be synced.
- SSH targets are discovered from `~/.ssh/config`.
- SSH targets are grouped under a submenu in the menu bar menu.
- Custom SSH target fields are available in Settings.
- Login startup uses the macOS 13+ `SMAppService` API.
- Settings can show the running SSH target name next to the menu bar icon.
- Settings window temporarily shows AutoRPF in the Dock and returns to menu-bar-only mode after closing.
- App icon generated with the image model and stored in `Assets.xcassets`.

## To Be Finished

- Manual run from Xcode on the target Mac.
- Manual login-item registration check from the built app bundle.
- Real SSH tunnel smoke test against a configured host.

## Possible Future Requirements

- Multiple simultaneous tunnels.
- Import/export settings.
- Per-target port overrides.
- Rich connection logs in a diagnostics window.
- Notarized release packaging.
