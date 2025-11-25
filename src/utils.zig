const std = @import("std");
const fs = std.fs;

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
    _ = prompt;
    _ = default_yes;
    // var stdin_buf: [4096]u8 = undefined; // 4KB buffer for stdin reader
    // var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    // const reader = &stdin_reader.interface;

    // var stdout_buf: [4096]u8 = undefined; // 4KB buffer for stdout writer
    // var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    // const writer = &stdout_writer.interface;

    // while (true) {
    //     if (default_yes) {
    //         try writer.*.print("{s} [Y/n]: ", .{prompt});
    //     } else {
    //         try writer.*.print("{s} [y/N]: ", .{prompt});
    //     }
    //     try writer.*.flush(); // I Ensure the prompt is visible immediately

    //     var line_buf: [512]u8 = undefined; // HERE i Separate buffer for the input line
    //     var fbs = std.io.fixedBufferStream(line_buf[0..]);
    //     const line_writer = fbs.writer();

    //     reader.*.streamUntilDelimiter(line_writer, '\n', null) catch |err| {
    //         if (err == error.EndOfStream) {
    //             if (fbs.pos == 0) return default_yes;
    //             // Proceeding with partial line if any data was read before EOF
    //         } else return err;
    //     };

    //     const line = fbs.getWritten();

    //     // Handle Windows \r\n by trimming trailing \r
    //     // (Since movebin is POSIX-only, no extra whitespace trimming needed)
    //     const trimmed = std.mem.trimRight(u8, line, "\r");

    //     if (trimmed.len == 0) {
    //         return default_yes;
    //     }

    //     const c = std.ascii.toLower(trimmed[0]);
    //     if (c == 'y') return true;
    //     if (c == 'n') return false;

    //     try writer.*.print("Invalid input. Please type y or n.\n", .{});
    //     try writer.*.flush();
    // }
    return error.Unimplemented;
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
