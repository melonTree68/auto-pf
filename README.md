# AutoPF

![AutoPF app icon](AutoPF/Assets.xcassets/AppIcon.appiconset/icon-128.png)

AutoPF is a small macOS menu bar app for starting and stopping an SSH port forwarding tunnel.

```bash
ssh -N -R <remote-port>:127.0.0.1:<local-port> <target>
ssh -N -L <local-port>:127.0.0.1:<remote-port> <target>
```

It is useful when you often need the same port forwarding tunnel and want simple menu bar controls instead of typing the SSH command each time.

## Requirements

- macOS 13 or newer.

## What It Does

- Starts or stops one active SSH tunnel.
- Switches between remote forwarding (`-R`, the default) and local forwarding (`-L`) from the menu bar and remembers the selection.
- Reads SSH targets from `~/.ssh/config`.
- Supports a custom SSH target.
- Lets you edit local and remote ports, with optional port sync.
- Can launch at login.
- Can show the running target name next to the menu bar icon.

## Build From Source

```bash
make build-release
```

After launch, AutoPF appears in the macOS menu bar.
