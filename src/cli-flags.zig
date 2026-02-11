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

    /// Checks if the help flag is enabled
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

    /// Get the custom output name if -o flag is provided
    /// Returns null if no -o flag is found
    pub fn getOutputName(self: *const Self) ?[:0]const u8 {
        const args_slice = self.getArgs();
        var i: usize = 0;
        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];

            // Check for -o flag
            if (std.mem.eql(u8, arg, "-o")) {
                // Next argument should be the output name
                if (i + 1 < args_slice.len) {
                    return args_slice[i + 1];
                }
                // -o provided but no value - could handle error here
                return null;
            }

            // Check for --output flag (optional long form)
            if (std.mem.eql(u8, arg, "--output")) {
                if (i + 1 < args_slice.len) {
                    return args_slice[i + 1];
                }
                return null;
            }
        }
        return null;
    }

    /// Get non-flag arguments (source path)
    /// Filters out flags and their values
    pub fn getPositionalArgs(self: *const Self, allocator: std.mem.Allocator) ![]const [:0]u8 {
        var positional = std.ArrayList([:0]const u8).init(allocator);
        errdefer positional.deinit();

        const args_slice = self.getArgs();
        var i: usize = 0;

        while (i < args_slice.len) : (i += 1) {
            const arg = args_slice[i];

            // Skip flags
            if (std.mem.startsWith(u8, arg, "-")) {
                // Skip value-taking flags
                if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                    i += 1; // Skip the next arg (the value)
                }
                continue;
            }

            try positional.append(arg);
        }

        return positional.toOwnedSlice();
    }
};
