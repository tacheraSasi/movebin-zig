const std = @import("std");

pub const default_prefix = "/usr/local";

pub fn resolve(allocator: std.mem.Allocator, env_map: *std.process.Environ.Map, cli: ?[]const u8) ![]u8 {
    if (cli) |p| {
        if (p.len > 0) return allocator.dupe(u8, p);
    }

    if (env_map.get("MOVEBIN_PREFIX")) |p| {
        if (p.len > 0) return allocator.dupe(u8, p);
    }

    return allocator.dupe(u8, default_prefix);
}

fn trimTrailingSeparators(path: []const u8) []const u8 {
    var end = path.len;
    while (end > 1 and path[end - 1] == std.fs.path.sep) end -= 1;
    return path[0..end];
}

pub fn isOnPath(env_map: *std.process.Environ.Map, dir: []const u8) bool {
    const path = env_map.get("PATH") orelse return false;
    const target = trimTrailingSeparators(dir);
    var it = std.mem.tokenizeScalar(u8, path, std.fs.path.delimiter);
    while (it.next()) |entry| {
        if (std.mem.eql(u8, trimTrailingSeparators(entry), target)) return true;
    }
    return false;
}

test "resolve prefers cli, then env, then default" {
    const allocator = std.testing.allocator;
    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try env_map.put("MOVEBIN_PREFIX", "/env/prefix");

    const from_cli = try resolve(allocator, &env_map, "/cli/prefix");
    defer allocator.free(from_cli);
    try std.testing.expectEqualStrings("/cli/prefix", from_cli);

    const from_env = try resolve(allocator, &env_map, null);
    defer allocator.free(from_env);
    try std.testing.expectEqualStrings("/env/prefix", from_env);

    const empty_cli = try resolve(allocator, &env_map, "");
    defer allocator.free(empty_cli);
    try std.testing.expectEqualStrings("/env/prefix", empty_cli);

    try env_map.put("MOVEBIN_PREFIX", "");
    const from_default = try resolve(allocator, &env_map, null);
    defer allocator.free(from_default);
    try std.testing.expectEqualStrings(default_prefix, from_default);
}

test "isOnPath matches entries and ignores trailing separators" {
    const allocator = std.testing.allocator;
    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try env_map.put("PATH", "/usr/bin:/usr/local/bin/");

    try std.testing.expect(isOnPath(&env_map, "/usr/bin"));
    try std.testing.expect(isOnPath(&env_map, "/usr/local/bin"));
    try std.testing.expect(!isOnPath(&env_map, "/opt/bin"));
}
