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
pub fn askYesNo(console:Console, prompt: []const u8, default_yes: bool) !bool {
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
