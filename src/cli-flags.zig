const std = @import("std");

/// Command line flags parser / helper
pub const CliFlags = struct {
    args: []const [:0]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize using the juicy main `init` (recommended)
    pub fn init(allocator: std.mem.Allocator, initt: std.process.Init) !Self {
        const all_args = try initt.minimal.args.toSlice(allocator);
        return Self{
            .args = all_args,
            .allocator = allocator,
        };
    }

    /// Free the memory allocated for arguments
    pub fn deinit(self: *const Self) void {
        self.allocator.free(self.args);   // toSlice allocates, so just free
    }

    // ────────────────────────────────────────────────
    // Convenience methods
    // ────────────────────────────────────────────────

    /// Returns only the arguments (excludes program name = args[0])
    pub fn getArgs(self: *const Self) []const [:0]u8 {
        if (self.args.len == 0) return &[_][:0]u8{};
        return self.args[1..];
    }

    /// Returns all arguments including program name
    pub fn rawArgs(self: *const Self) []const [:0]u8 {
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

    pub fn getOutputName(self: *const Self) ?[:0]const u8 {
        const args_slice = self.getArgs();
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                if (i + 1 < args_slice.len) {
                    return args_slice[i + 1];
                }
                return null;
            }
        }
        return null;
    }

    /// Get non-flag arguments (source path)
    pub fn getPositionalArgs(self: *const Self, allocator: std.mem.Allocator) ![]const [:0]u8 {
        const args_slice = self.getArgs();
        var count: usize = 0;
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (std.mem.startsWith(u8, arg, "-")) {
                if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                    i += 1;
                }
                continue;
            }
            count += 1;
        }

        var positional = try allocator.alloc([:0]u8, count);
        var pos_idx: usize = 0;
        i = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];
            if (std.mem.startsWith(u8, arg, "-")) {
                if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                    i += 1;
                }
                continue;
            }
            positional[pos_idx] = @constCast(arg);
            pos_idx += 1;
        }
        return positional;
    }
};