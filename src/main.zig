const std = @import("std");
const fs = std.fs;
const utils = @import("utils.zig");
const Console = @import("console.zig").Console;
const constants = @import("constants.zig");
const CliFlags = @import("cli-flags.zig").CliFlags;

const heap = std.heap;
const string: type = []const u8;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    
    const cli = try CliFlags.init(allocator);
    defer cli.argsFree();

    var write_buffer: [1024]u8 = undefined;
    var read_buffer: [1024]u8 = undefined;
    var console: Console = undefined;
    console.init(&write_buffer, &read_buffer);

    if (cli.getArgs().len < 2) {
        try console.printLine("Usage: sudo movebin <binary_path> [-f|--force] [--no-backup]\n", .{});
        return;
    }
    
    const version_enabled = cli.isVersionFlagEnabled();
    if (version_enabled) {
        try console.printLine("movebin version {s}\n", .{constants.VERSION});
        return;
    }

    const src_path = cli.getArgs()[0];
    if (!try utils.fileExists(src_path)) {
        try console.printLine("Source file not found: {s}\n", .{src_path});
        return;
    }

    const dest_filename = std.fs.path.basename(src_path);
    const dest_path = try std.fs.path.join(allocator, &.{ "/usr/local/bin", dest_filename });
    defer allocator.free(dest_path);

    const force = cli.isForceFlagEnabled();
    const no_backup = cli.isNoBackupFlagEnabled();

    var backed_up_path: ?[]u8 = null;
    defer if (backed_up_path) |p| allocator.free(p);

    const dest_exists = try utils.fileExists(dest_path);

    if (dest_exists) {
        if (!force) {
            const confirmed = try utils.askYesNo(console, "Destination already exists. Overwrite?", false);
            if (!confirmed) {
                try console.printLine("Aborted.\n", .{});
                return;
            }
        }

        // Decide whether to backup
        if (utils.shouldCreateBackup(force, no_backup)) {
            try console.printLine("Creating backup...\n", .{});
            backed_up_path = try utils.backupAndRemoveExistingBin(
                allocator,
                dest_path,
                null, // or i will pass custom backup dir
            );
            if (backed_up_path) |bp| {
                try console.printLine("Backup created: {s}\n", .{bp});
            }
        } else {
            try console.printLine("Removing existing file (no backup requested)...\n", .{});
            try utils.deleteExistingBin(dest_path);
        }
    }

    try utils.copyToDestination(src_path, dest_path);

    const file = try fs.cwd().openFile(dest_path, .{ .mode = .read_write });
    defer file.close();
    try file.chmod(0o755);

    try console.printLine("Successfully installed: {s}\n", .{dest_path});
}
