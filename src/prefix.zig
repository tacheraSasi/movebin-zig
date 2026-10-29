const std = @import("std");

pub const default_prefix = "/usr/local";

pub fn resolve(allocator: std.mem.Allocator, env_map: *std.process.Environ.Map, cli: ?[]const u8) ![]u8 {
    if (cli) |p| return allocator.dupe(u8, p);

    if (env_map.get("MOVEBIN_PREFIX")) |p| {
        if (p.len > 0) return allocator.dupe(u8, p);
    }

    return allocator.dupe(u8, default_prefix);
}

pub fn isOnPath(env_map: *std.process.Environ.Map, dir: []const u8) bool {
    const path = env_map.get("PATH") orelse return false;
    var it = std.mem.tokenizeScalar(u8, path, std.fs.path.delimiter);
    while (it.next()) |entry| {
        if (std.mem.eql(u8, entry, dir)) return true;
    }
    return false;
}
