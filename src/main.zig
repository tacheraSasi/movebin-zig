const std = @import("std");

const stdio = @import("stdio");

const CliFlags = @import("cli-flags.zig").CliFlags;
const constants = @import("constants.zig");
const prefix_core = @import("prefix.zig");
const utils = @import("utils.zig");

const string: type = []const u8;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const env = init.environ_map;
    const args = try init.minimal.args.toSlice(allocator);

    const cli = try CliFlags.init(args);
    defer cli.deinit(allocator);

    var write_buffer: [1024]u8 = undefined;
    var read_buffer: [1024]u8 = undefined;

    var console: stdio.Console = undefined;
    console.init(io, &write_buffer, &read_buffer);

    if (cli.getArgs().len == 0) {
        try console.printLine(utils.HelpText(), .{});
        return;
    }

    const version_enabled = cli.isVersionFlagEnabled();
    if (version_enabled) {
        try console.printLine("movebin version {s}", .{constants.VERSION});
        return;
    }

    const help_enabled = cli.isHelpFlagEnabled();
    if (help_enabled) {
        try console.printLine(utils.HelpText(), .{});
        return;
    }

    if (cli.hasMissingValue()) {
        try console.printLine("Error: Missing value for option", .{});
        try console.printLine(utils.HelpText(), .{});
        return;
    }

    // Getting the positional arguments
    const positional_args = try cli.getPositionalArgs(allocator);
    defer allocator.free(positional_args);

    if (positional_args.len == 0) {
        try console.printLine("Error: No source file specified", .{});
        try console.printLine(utils.HelpText(), .{});
        return;
    }

    const src_path = positional_args[0];
    const src_kind = std.Io.Dir.cwd().statFile(io, src_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try console.printLine("Source file not found: {s}", .{src_path});
            return;
        },
        else => return err,
    };
    if (src_kind.kind == .directory) {
        try console.printLine("Source path is a directory: {s}", .{src_path});
        return;
    }

    const prefix = try prefix_core.resolve(allocator, env, cli.getPrefix());
    defer allocator.free(prefix);

    // Determine destination filename
    const dest_filename = cli.getOutputName() orelse std.fs.path.basename(src_path);
    if (dest_filename.len == 0 or
        std.mem.indexOfScalar(u8, dest_filename, std.fs.path.sep) != null or
        std.fs.path.isAbsolute(dest_filename))
    {
        try console.printLine("Error: Invalid output name: {s}", .{dest_filename});
        return;
    }
    const dest_path = try std.fs.path.join(allocator, &.{ prefix, "bin", dest_filename });
    defer allocator.free(dest_path);

    const force = cli.isForceFlagEnabled();
    const no_backup = cli.isNoBackupFlagEnabled();

    var backed_up_path: ?[]u8 = null;
    defer if (backed_up_path) |p| allocator.free(p);

    const dest_exists = try utils.fileExists(io, dest_path);
    if (dest_exists) {
        if (!force) {
            const confirmed = try utils.askYesNo(console, "Destination already exists. Overwrite?", false);
            if (!confirmed) {
                try console.printLine("Aborted.", .{});
                return;
            }
        }

        if (utils.shouldCreateBackup(no_backup)) {
            try console.printLine("Creating backup...", .{});
            backed_up_path = utils.backupAndRemoveExistingBin(
                allocator,
                io,
                dest_path,
                null, // custom backup dir if needed
            ) catch |err| switch (err) {
                error.AccessDenied => {
                    try console.printLine("error: Permission denied —> try running with sudo", .{});
                    return;
                },
                else => |e| return e,
            };
            if (backed_up_path) |bp| {
                try console.printLine("Backup created: {s}", .{bp});
            }
        } else {
            try console.printLine("Removing existing file (no backup requested)...", .{});
            try utils.deleteExistingBin(io, dest_path);
        }
    }

    const bin_dir = std.fs.path.dirname(dest_path).?;
    try std.Io.Dir.cwd().createDirPath(io, bin_dir);

    try utils.copyToDestination(io, src_path, dest_path);

    // Make executable (macOS/Linux)
    if (comptime std.Io.File.Permissions.has_executable_bit) {
        const file = try std.Io.Dir.cwd().openFile(io, dest_path, .{ .mode = .read_write });
        defer file.close(io);
        try file.setPermissions(io, @as(std.Io.File.Permissions, @fromBackingInt(0o755)));
    }

    try console.printLine("Successfully installed: {s}", .{dest_path});

    if (!prefix_core.isOnPath(env, bin_dir)) {
        try console.printLine("Warning: {s} is not in your PATH", .{bin_dir});
    }
}
