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
    var stdin_buf: [4096]u8 = undefined; // 4KB buffer for stdin reader
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const reader = &stdin_reader.interface;

    var stdout_buf: [4096]u8 = undefined; // 4KB buffer for stdout writer
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    while (true) {
        if (default_yes) {
            try writer.print("{s} [Y/n]: ", .{prompt});
        } else {
            try writer.print("{s} [y/N]: ", .{prompt});
        }
        try writer.flush(); // I Ensure the prompt is visible immediately

        var line_buf: [512]u8 = undefined; // NOTE: Here I Separate buffer for the input line 
        const mb_line = try reader.readUntilDelimiterOrEof(line_buf[0..], '\n');
        const line = mb_line orelse return default_yes; // Treating EOF as default

        // Will Handle Windows \r\n 
        // For now I Only trim \r from the right end
        // Since movebin is only for posix, I won't handle other whitespace
        const trimmed = std.mem.trimRight(u8, line, "\r"); 

        if (trimmed.len == 0) {
            return default_yes;
        }

        const c = std.ascii.toLower(trimmed[0]);
        if (c == 'y') return true;
        if (c == 'n') return false;

        try writer.print("Invalid input. Please type y or n.\n", .{});
        try writer.flush();
    }
}
