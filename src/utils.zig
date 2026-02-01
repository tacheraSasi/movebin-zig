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
        if  (std.mem.eql(u8, arg, "--no-backup")) {
            return true;
        }
    }
    return false;
}

/// Backup the existing binary and remove it from the destination path.
/// `usr/local/bin/somebinary` -> `usr/local/bin/.movebin_backups/somebinary_timestamp`
/// If backup_dir is null, a default hidden directory next to the destination will be used.
pub fn backupAndRemoveExistingBin(
    allocator: *std.mem.Allocator,
    src_path: []const u8,
    backup_dir: ?[]const u8, // if null, we use default hidden directory next to destination
) ![]u8 // returns the allocated backup path string
{
    const dest_path = try fs.cwd().realPath(src_path);
    const dest_dir = try fs.path.dirname(allocator, dest_path);
    var backup_directory: []const u8 = "";

    if (backup_dir) {
        backup_directory = backup_dir.?;
    } else {
        backup_directory = try fs.path.join(allocator, &.{ dest_dir, ".movebin_backups" });

        if (!try fileExists(backup_directory)) {
            try fs.cwd().createDir(backup_directory, 0o755);
        }
    }

    const timestamp = std.time.timestamp();
    const backup_filename = try fs.path.basename(allocator, dest_path);
    const backup_path = try fs.path.join(
        allocator,
        &.{ backup_directory, std.fmt.allocPrint(allocator, "{s}_{d}", .{ backup_filename, timestamp }) },
    );

    // Copy the existing binary to the backup location
    try fs.cwd().copyFile(dest_path, std.fs.cwd(), backup_path, .{});

    // TODO: i will implement retention logic here to delete old backups

    // Delete the existing binary
    try deleteExistingBin(dest_path);

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
