const std = @import("std");
const fs = std.fs;
const Console = @import("console.zig").Console;

/// Check if a file exists at the given path.
pub fn fileExists(path: []const u8) !bool {
    var found = true;
    fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => found = false,
        else => return err,
    };
    return found;
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

        const c = std.ascii.toLower(line[0]);
        if (c == 'y') return true;
        if (c == 'n') return false;

        try console.print("Invalid input. Please type y or n.\n", .{});
    }
}

pub fn isVersionFlagEnabled(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            return true;
        }
    }
    return false;
}

/// Check if the force flag (-f or --force) is present in the arguments.
pub fn isForceFlagEnabled(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            return true;
        }
    }
    return false;
}

/// Check if the no-backup flag (--no-backup) is present in the arguments.
pub fn isNoBackupFlag(args: []const []const u8) bool {
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--no-backup")) {
            return true;
        }
    }
    return false;
}

pub fn shouldCreateBackup(force: bool, no_backup: bool) bool {
    _ = force;
    if (no_backup) return false;
    return true; // backup by default — even with force
    // Alternative (more aggressive): return force or !force;
}

/// Backup the existing binary and remove it from the destination path.
/// `usr/local/bin/somebinary` -> `usr/local/bin/.movebin_backups/somebinary_timestamp`
/// If backup_dir is null, a default hidden directory next to the destination will be used.
pub fn backupAndRemoveExistingBin(
    allocator: std.mem.Allocator,
    dest_path: []const u8,
    backup_dir: ?[]const u8,
) !?[]u8 { // returns backup path or null if no backup was made
    if (!try fileExists(dest_path)) {
        return null;
    }

    const dir = fs.path.dirname(dest_path) orelse ".";
    const filename = fs.path.basename(dest_path);

    const backup_parent = backup_dir orelse
        try fs.path.join(allocator, &.{ dir, ".movebin_backups" });

    defer if (backup_dir == null) allocator.free(backup_parent);

    // Create backup dir if needed
    if (!try fileExists(backup_parent)) {
        try fs.cwd().makeDir(backup_parent);
    }

    const timestamp = std.time.timestamp();
    const backup_name = try std.fmt.allocPrint(
        allocator,
        "{s}_{d}",
        .{ filename, timestamp },
    );
    defer allocator.free(backup_name);

    const backup_path = try fs.path.join(
        allocator,
        &.{ backup_parent, backup_name },
    );

    try fs.cwd().copyFile(dest_path, fs.cwd(), backup_path, .{});

    try fs.deleteFileAbsolute(dest_path);

    return backup_path;
}

///Copy the bin to the destination path
pub fn copyToDestination(src_path: []const u8, dest_path: []const u8) !void {
    try fs.cwd().copyFile(src_path, std.fs.cwd(), dest_path, .{});
    // const dest_file = try fs.cwd().openFile(dest_path, .{ .read = true, .write = true });
    // defer dest_file.close();
    // try fs.File.setPermissions(dest_file, .{ .user = .rwx, .group = .rx, .other = .rx });
}

//TODO: Add a function to back up existing binary before deletion

/// Delete the existing binary at the destination path.
pub fn deleteExistingBin(path: []const u8) !void {
    try fs.deleteFileAbsolute(path);
}
