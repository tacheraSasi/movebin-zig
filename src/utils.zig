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
    var stdin_buf: [4096]u8 = undefined; // 4KB buffer for stdin
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);

    var stdout_buf: [4096]u8 = undefined; // 4KB buffer for stdout
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);

    while (true) {
        if (default_yes) {
            try stdout_writer.print("{s} [Y/n]: ", .{prompt});
            try stdout_writer.flush();
        } else {
            try stdout_writer.print("{s} [y/N]: ", .{prompt});
            try stdout_writer.flush();
        }

        const line = try stdin_reader.readUntilDelimiterOrEof(&stdin_buf, '\n');
        const trimmed = std.mem.trimRight(u8, line, "\r\n");

        if (trimmed.len == 0) {
            return default_yes;
        }

        const c = std.ascii.toLower(trimmed[0]);
        if (c == 'y') return true;
        if (c == 'n') return false;

        try std.debug.print("Invalid input. Please type y or n.\n", .{});
    }
}
