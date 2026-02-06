# movebin-zig

movebin-zig is a small utility to install (move) a local binary into a system directory such as `/usr/local/bin`.

## Features

- Copy a binary to `/usr/local/bin` and avoid accidental overwrites.
- Prompts before overwriting; supports a force flag to skip confirmation.

## Prerequisites

- Zig (the project uses the included `build.zig`). Ensure `zig` is available on your PATH.
- You will generally need elevated privileges (e.g. `sudo`) to install into `/usr/local/bin`.

## Build

To build the project locally:

```bash
zig build
```

The built executable is placed under `zig-out/bin/movebin`.

To run the program directly from the build output:

```bash
./zig-out/bin/movebin <path/to/binary>
```

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

## Notes

- The project contains helper utilities in `src/utils.zig` (for checking file existence, prompting, and handling the `-f`/`--force` flags).
- `build.zig` is provided; see it for additional build targets.

## Contributing

1. Fork the repository and create a topic branch.
2. Make your changes and run `zig build` (or `zig test` if you add tests).
3. Open a pull request with a clear description of your changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

