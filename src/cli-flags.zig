const std = @import("std");

/// Flags that consume the next argument as their value.
const value_flags = [_][]const u8{ "-o", "--output", "-p", "--prefix" };

fn isValueFlag(arg: []const u8) bool {
    for (value_flags) |flag| {
        if (std.mem.eql(u8, flag, arg)) return true;
    }
    return false;
}

fn isFlag(arg: []const u8) bool {
    return arg.len > 1 and arg[0] == '-';
}
/// Command line flags parser / helper
pub const CliFlags = struct {
    args: []const [:0]const u8,

    const Self = @This();

    /// Initialize by passing the args
    pub fn init(args: []const [:0]const u8) !Self {
        return Self{
            .args = args,
        };
    }

    /// Free the memory allocated for arguments
    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        allocator.free(self.args); // toSlice allocates, so just free
    }

    // ────────────────────────────────────────────────
    // Convenience methods
    // ────────────────────────────────────────────────

    /// Returns only the arguments (excludes program name = args[0])
    pub fn getArgs(self: *const Self) []const [:0]const u8 {
        if (self.args.len == 0) return &[_][:0]u8{};
        return self.args[1..];
    }

    /// Returns all arguments including program name
    pub fn rawArgs(self: *const Self) []const [:0]const u8 {
        return self.args;
    }

    pub fn len(self: *const Self) usize {
        return if (self.args.len > 0) self.args.len - 1 else 0;
    }

    pub fn rawLen(self: *const Self) usize {
        return self.args.len;
    }

    pub fn isVersionFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                return true;
            }
        }
        return false;
    }

    pub fn isHelpFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                return true;
            }
        }
        return false;
    }

    pub fn isForceFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
                return true;
            }
        }
        return false;
    }

    pub fn isNoBackupFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "--no-backup")) {
                return true;
            }
        }
        return false;
    }

    /// Get non-flag arguments (source path)
    pub fn getPositionalArgs(self: *const Self, allocator: std.mem.Allocator) ![]const [:0]const u8 {
        const args_slice = self.getArgs();

        // Upper bound: at most every arg is positional.
        const list = try allocator.alloc([:0]const u8, args_slice.len);
        errdefer allocator.free(list);
        var n: usize = 0;

        var options_done = false;
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (!options_done) {
                if (std.mem.eql(u8, arg, "--")) {
                    options_done = true;
                    continue;
                }
                if (isFlag(arg)) {
                    if (isValueFlag(arg)) i += 1; // skip this flag's value
                    continue;
                }
            }
            list[n] = arg;
            n += 1;
        }

        return allocator.realloc(list, n); // shrink to the real count
    }

    /// Returns true when a value-taking flag has no value (or no value left).
    pub fn hasMissingValue(self: *const Self) bool {
        const args_slice = self.getArgs();
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (std.mem.eql(u8, arg, "--")) return false;
            if (isValueFlag(arg)) {
                if (i + 1 >= args_slice.len or std.mem.eql(u8, args_slice[i + 1], "--")) {
                    return true;
                }
                i += 1;
            }
        }
        return false;
    }

    /// Looks up `-x value`, `--long value` or `--long=value`.
    pub fn getOptionValue(self: *const Self, short: []const u8, long: []const u8) ?[:0]const u8 {
        const args_slice = self.getArgs();
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (std.mem.eql(u8, arg, "--")) return null;
            if (std.mem.eql(u8, arg, short) or std.mem.eql(u8, arg, long)) {
                return if (i + 1 < args_slice.len) args_slice[i + 1] else null;
            }
            if (std.mem.startsWith(u8, arg, long) and arg.len > long.len and arg[long.len] == '=') {
                return arg[long.len + 1 ..];
            }
        }
        return null;
    }

    pub fn getOutputName(self: *const Self) ?[:0]const u8 {
        return self.getOptionValue("-o", "--output");
    }

    pub fn getPrefix(self: *const Self) ?[:0]const u8 {
        return self.getOptionValue("-p", "--prefix");
    }
};

test "positional args skip option values and honor --" {
    const allocator = std.testing.allocator;
    const args = [_][:0]const u8{ "movebin", "-p", "/tmp/prefix", "script.sh", "--", "-not-a-flag" };
    const cli = try CliFlags.init(&args);

    const positional = try cli.getPositionalArgs(allocator);
    defer allocator.free(positional);

    try std.testing.expectEqual(@as(usize, 2), positional.len);
    try std.testing.expectEqualStrings("script.sh", positional[0]);
    try std.testing.expectEqualStrings("-not-a-flag", positional[1]);
}

test "option values support separate and attached forms" {
    const separate = [_][:0]const u8{ "movebin", "--prefix", "/tmp/x", "file" };
    const cli_separate = try CliFlags.init(&separate);
    try std.testing.expectEqualStrings("/tmp/x", cli_separate.getPrefix().?);

    const attached = [_][:0]const u8{ "movebin", "--prefix=/tmp/y", "file" };
    const cli_attached = try CliFlags.init(&attached);
    try std.testing.expectEqualStrings("/tmp/y", cli_attached.getPrefix().?);
}

test "missing option value is detected" {
    const args = [_][:0]const u8{ "movebin", "file", "-p" };
    const cli = try CliFlags.init(&args);
    try std.testing.expect(cli.hasMissingValue());

    const complete = [_][:0]const u8{ "movebin", "file", "-p", "/tmp/x" };
    const cli_complete = try CliFlags.init(&complete);
    try std.testing.expect(!cli_complete.hasMissingValue());
}
