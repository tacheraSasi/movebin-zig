const std = @import("std");
const Console = @import("console.zig").Console;

/// Check if a file exists at the given path.
pub fn fileExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

/// Prompt the user with a yes/no question.
pub fn askYesNo(console: Console, prompt: []const u8, default_yes: bool) !bool {
    while (true) {
        if (default_yes) {
            try console.print("{s} [Y/n]: ", .{prompt});
        } else {
            try console.print("{s} [y/N]: ", .{prompt});
        }
        const line: []u8 = try console.readLine();
        if (line.len == 0) {
            return default_yes;
        }
        const c = std.ascii.toLower(line[0]);
        if (c == 'y') return true;
        if (c == 'n') return false;
        try console.print("Invalid input. Please type y or n.\n", .{});
    }
}

/// Check if the version flag (-v or --version) is present
pub fn isVersionFlagEnabled(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            return true;
        }
    }
    return false;
}

/// Check if the force flag (-f or --force) is present
pub fn isForceFlagEnabled(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            return true;
        }
    }
    return false;
}

/// Check if the no-backup flag (--no-backup) is present
pub fn isNoBackupFlag(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--no-backup")) {
            return true;
        }
    }
    return false;
}

pub fn shouldCreateBackup(no_backup: bool) bool {
    if (no_backup) return false;
    return true; // backup by default
}

/// Backup the existing binary and remove it.
/// Returns the backup path (or null if no backup was made).
pub fn backupAndRemoveExistingBin(
    allocator: std.mem.Allocator,
    io: std.Io,
    dest_path: []const u8,
    backup_dir: ?[]const u8,
) !?[]u8 {
    if (!try fileExists(io, dest_path)) {
        return null;
    }

    const dir = std.fs.path.dirname(dest_path) orelse ".";
    const filename = std.fs.path.basename(dest_path);

    const backup_parent = backup_dir orelse
        try std.fs.path.join(allocator, &.{ dir, ".movebin_backups" });
    defer if (backup_dir == null) allocator.free(backup_parent);

    // Create backup directory if it doesn't exist
    if (!try fileExists(io, backup_parent)) {
        try std.Io.Dir.cwd().makeDir(io, backup_parent);
    }

    const timestamp = std.time.timestamp();
    const backup_name = try std.fmt.allocPrint(
        allocator,
        "{s}_{d}",
        .{ filename, timestamp },
    );
    defer allocator.free(backup_name);

    const backup_path = try std.fs.path.join(allocator, &.{ backup_parent, backup_name });

    // Copy then delete original
    try std.Io.Dir.cwd().copyFile(io, dest_path, std.Io.Dir.cwd(), backup_path, .{});
    try std.Io.Dir.cwd().deleteFile(io, dest_path);

    return backup_path;
}

/// Copy the binary to the destination path
pub fn copyToDestination(io: std.Io, src_path: []const u8, dest_path: []const u8) !void {
    try std.Io.Dir.cwd().copyFile(io, src_path, std.Io.Dir.cwd(), dest_path, .{});
}

/// Delete the existing binary at the destination path.
pub fn deleteExistingBin(io: std.Io, path: []const u8) !void {
    try std.Io.Dir.cwd().deleteFile(io, path);
}

/// Returns the help text
pub fn HelpText() []const u8 {
    return
    \\Usage: sudo movebin <binary_path> [OPTIONS]
    \\
    \\Options:
    \\ -o, --output <name>   Set a custom binary name
    \\ -f, --force           Force overwrite without prompting
    \\ --no-backup           Skip backup creation
    \\ -h, --help            Show this help message
    \\ -v, --version         Show version information
    \\
    \\Examples:
    \\ movebin ./my-script
    \\ movebin ./my-script -o custom
    \\ movebin ./my-script -o tool -f
    \\
    ;
}
