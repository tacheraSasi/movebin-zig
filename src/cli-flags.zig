const std = @import("std");

/// Initializes the command-line flags.
pub const CliFlags = struct {
    args: []const u8,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initializes the command-line flags.
    pub fn init(self: *Self, allocator: std.mem.Allocator) !CliFlags {
        self.args = try std.process.argsAlloc(allocator);
    }

    /// Returns the command-line arguments.
    /// From the first argument (excluding the program name) args[1..].
    pub fn getArgs(self:*const Self) []const u8 {
        return self.args[1..];
    }

    /// Returns the number of command-line arguments.
    pub fn len(self:*const Self) usize {
        return self.args.len;
    }

    pub fn isVersionFlagEnabled(self:*const Self) bool {
        for (self.args) |arg| {
            if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                return true;
            }
        }
        return false;
    }

    /// Check if the force flag (-f or --force) is present in the arguments.
    pub fn isForceFlagEnabled(self:*const Self) bool {
        for (self.args) |arg| {
            if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
                return true;
            }
        }
        return false;
    }

    /// Check if the no-backup flag (--no-backup) is present in the arguments.
    pub fn isNoBackupFlag(self:*const Self) bool {
        for (self.args) |arg| {
            if (std.mem.eql(u8, arg, "--no-backup")) {
                return true;
            }
        }
        return false;
    }

    /// Frees the memory allocated for the command-line arguments.
    pub fn argsFree(self:*const Self) void {
        std.process.argsFree(self.allocator, self.args);
    }
};
