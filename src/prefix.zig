const std = @import("std");

pub const default_prefix = "/usr/local";

pub fn resolve(allocator: std.mem.Allocator, cli: ?[]const u8) ![]u8 {
    if (cli) |p| return allocator.dupe(u8, p);

    if (std.process.getEnvVarOwned(allocator, "MOVEBIN_PREFIX")) |p| {
        if (p.len > 0) return p;
        allocator.free(p);
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {},
        else => return err,
    }
    return allocator.dupe(u8, default_prefix);
}
