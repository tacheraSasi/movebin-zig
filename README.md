# movebin-zig

movebin-zig is a small utility to install (move) a local binary into a system directory such as `/usr/local/bin`.

## Features

- Copy a binary to `/usr/local/bin` and avoid accidental overwrites.
- Install to a custom prefix with `-p`/`--prefix` or `$MOVEBIN_PREFIX`.
- Prompts before overwriting; supports a force flag to skip confirmation.
- Warns when the install directory is not on your `PATH`.

## Prerequisites

- Zig (the project uses the included `build.zig`). Ensure `zig` is available on your PATH.
- You will generally need elevated privileges (e.g. `sudo`) to install into `/usr/local/bin`.

## Installation

### macOS (Apple Silicon)

```bash
curl -L https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-darwin-arm64.tar.gz -o movebin.tar.gz
sudo tar -C /usr/local/bin -xzf movebin.tar.gz
rm movebin.tar.gz
```

### macOS (Intel)

```bash
curl -L https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-darwin-amd64.tar.gz -o movebin.tar.gz
sudo tar -C /usr/local/bin -xzf movebin.tar.gz
rm movebin.tar.gz
```

### Linux (x86_64)

```bash
curl -L https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-linux-amd64.tar.gz -o movebin.tar.gz
sudo tar -C /usr/local/bin -xzf movebin.tar.gz
rm movebin.tar.gz
```

### Linux (aarch64)

```bash
curl -L https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-linux-arm64.tar.gz -o movebin.tar.gz
sudo tar -C /usr/local/bin -xzf movebin.tar.gz
rm movebin.tar.gz
```

### Windows (x86_64)

```bash
curl -L https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-windows-amd64.zip -o movebin.zip
# Extract and place movebin.exe somewhere in your PATH
```

Or with PowerShell (admin):

```powershell
Invoke-WebRequest -Uri https://github.com/tacheraSasi/movebin-zig/releases/latest/download/movebin-windows-amd64.zip -OutFile movebin.zip
Expand-Archive movebin.zip -DestinationPath C:\Windows\System32
Remove-Item movebin.zip
```

## Build from source

To build the project locally:

```bash
zig build
```

The built executable is placed under `zig-out/bin/movebin`.

To run the program directly from the build output:

```bash
./zig-out/bin/movebin <path/to/binary>
```

A `Makefile` is also provided for convenience:

| Command | Description |
|---------|-------------|
| `make build` | Build the project |
| `make run` | Build and run |
| `make test` | Run tests |
| `make lint` | Check formatting |
| `make clean` | Remove build artifacts |
| `make build-all` | Cross-compile for all platforms |
| `make release` | Build archives and create a GitHub release |

## Usage

Basic usage:

```bash
sudo movebin <binary_path> [args...]
```

If a file already exists at the destination the program prompts before overwriting. You can skip the prompt with the force flag:

```bash
sudo movebin -f <binary_path>
sudo movebin --force <binary_path>
```

Example:

```bash
sudo movebin ./my-tool
# destination will be: /usr/local/bin/my-tool
```

## Custom install prefix

By default, movebin installs into `/usr/local/bin`. Use `-p`/`--prefix` (or the `MOVEBIN_PREFIX` environment variable) to install into `<prefix>/bin` instead:

```bash
movebin ./my-script -p ~/.local
# destination will be: ~/.local/bin/my-script

MOVEBIN_PREFIX=~/.local movebin ./my-script
# destination will be: ~/.local/bin/my-script
```

The prefix is resolved in this order:

1. `-p` / `--prefix` command-line flag
2. `MOVEBIN_PREFIX` environment variable
3. Default: `/usr/local`

The target `bin` directory is created if it does not exist. If it is not on your `PATH`, movebin prints a warning after installing.

## Notes

- The project contains helper utilities in `src/utils.zig` (for checking file existence, prompting, and handling the `-f`/`--force` flags).
- `build.zig` is provided; see it for additional build targets.

## Contributing

1. Fork the repository and create a topic branch.
2. Make your changes and run `zig build` (or `zig test` if you add tests).
3. Open a pull request with a clear description of your changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

