# AutoRPF

![AutoRPF app icon](AutoRPF/Assets.xcassets/AppIcon.appiconset/icon-128.png)

AutoRPF is a native macOS menu bar app for managing a single reverse SSH port forwarding tunnel.

The initial tunnel command shape is:

```bash
ssh -N -R 127.0.0.1:<remote-port>:127.0.0.1:<local-port> <target>
```

## Features

- Menu bar control for starting and stopping one active reverse SSH tunnel.
- SSH target discovery from `~/.ssh/config`.
- Custom SSH target configuration.
- Editable local and remote ports.
- Optional port sync mode, where the remote port mirrors the local port.
- Login startup toggle using the modern macOS `SMAppService` API.
- Settings window with temporary Dock presence: AutoRPF normally stays out of the Dock, appears there while Settings is open, then returns to menu-bar-only mode after Settings closes.

## Requirements

- macOS 13 or newer.
- Xcode 26 or newer is recommended for this project.
- A reachable SSH target with reverse forwarding allowed.

## Build and Run

Open the project in Xcode:

```bash
open AutoRPF.xcodeproj
```

Select the `AutoRPF` scheme, choose `My Mac`, and run.

You can also build and run from the command line:

```bash
xcodebuild -project AutoRPF.xcodeproj -scheme AutoRPF -configuration Debug -derivedDataPath .build/DerivedData build
open .build/DerivedData/Build/Products/Debug/AutoRPF.app
```

After launch, look for the AutoRPF icon in the macOS menu bar.

## Testing

Run the unit tests with:

```bash
xcodebuild -project AutoRPF.xcodeproj -scheme AutoRPF -configuration Debug -derivedDataPath .build/DerivedData test
```

The tests cover SSH config parsing, port syncing, and SSH command argument construction.

## Status

AutoRPF is early-stage software. See [`docs/requirements.md`](docs/requirements.md) for completed, pending, and future requirements.
