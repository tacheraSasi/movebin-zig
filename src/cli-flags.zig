const std = @import("std");

/// Command line flags parser / helper
pub const CliFlags = struct {
    // Using mutable child typehere  to match argsFree() expectation
    args: []const [:0]u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize the CliFlags struct with the provided allocator
    pub fn init(allocator: std.mem.Allocator) !Self {
        const all_args = try std.process.argsAlloc(allocator);
        errdefer std.process.argsFree(allocator, all_args);

        return Self{
            .args = all_args,
            .allocator = allocator,
        };
    }

    /// Free the memory allocated for arguments
    pub fn deinit(self: *const Self) void {
        std.process.argsFree(self.allocator, self.args);
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

    /// Number of **user** arguments (excludes program name)
    pub fn len(self: *const Self) usize {
        return if (self.args.len > 0) self.args.len - 1 else 0;
    }

    /// Total number of arguments including argv[0]
    pub fn rawLen(self: *const Self) usize {
        return self.args.len;
    }

    /// Checks if the version flag is enabled
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

    /// Checks if the force flag is enabled
    pub fn isForceFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
                return true;
            }
        }
        return false;
    }

    /// Checks if the no-backup flag is enabled
    pub fn isNoBackupFlagEnabled(self: *const Self) bool {
        for (self.getArgs()) |arg| {
            if (std.mem.eql(u8, arg, "--no-backup")) {
                return true;
            }
        }
        return false;
    }
};