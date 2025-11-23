const fs = @import("std").fs;

pub fn FileExists(path: []const u8) !bool {
    var found = true;
    fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => found = false,
        else => return err,
    };
    return found;
}
