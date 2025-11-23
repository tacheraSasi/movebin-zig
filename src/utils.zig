const std = @import("std");

pub fn FileExists(allocator: std.mem.Allocator, path: []const u8) !bool {
    allocator; // suppress unused variable warning
    const file = try std.fs.cwd().openFile(path, .{ .read = true }) catch |err| {
        if (err == std.fs.FileError.FileNotFound) {
            return false;
        }
        return err;
    };
    defer file.close();
    return true;
}
