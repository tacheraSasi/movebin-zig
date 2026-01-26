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
pub fn askYesNo(prompt: []const u8, default_yes: bool) !bool {
   	var write_buffer:[1024]u8 = undefined;
	var read_buffer:[1024]u8 = undefined;
	var console:Console = undefined;
	console.init(&write_buffer, &read_buffer);
   
	try console.printLine("Hello World!", .{});
    var stdin_buf: [4096]u8 = undefined; // 4KB buffer for stdin reader
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const reader = &stdin_reader.interface;

    var stdout_buf: [4096]u8 = undefined; // 4KB buffer for stdout writer
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    while (true) {
        if (default_yes) {
            try console.print("{s} [Y/n]: ", .{prompt});
        } else {
            try console.print("{s} [y/N]: ", .{prompt});
        }
        
        

        const c = std.ascii.toLower(trimmed[0]);
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
