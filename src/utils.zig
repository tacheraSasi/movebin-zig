const std = @import("std");
const fs = std.fs;

pub fn FileExists(path: []const u8) !bool {
    var found = true;
    fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => found = false,
        else => return err,
    };
    return found;
}

pub fn askYesNo(prompt: []const u8, default_yes: bool) !bool {
    const stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    var buf: [16]u8 = undefined;

    while (true) {
        if (default_yes) {
            try stdout.print("{s} [Y/n]: ", .{prompt});
        } else {
            try stdout.print("{s} [y/N]: ", .{prompt});
        }

        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');
        const trimmed = std.mem.trimRight(u8, line, "\r\n");

        if (trimmed.len == 0) {
            return default_yes;
        }

        const c = std.ascii.toLower(trimmed[0]);
        if (c == 'y') return true;
        if (c == 'n') return false;

        try stdout.print("Invalid input. Please type y or n.\n", .{});
    }
}
