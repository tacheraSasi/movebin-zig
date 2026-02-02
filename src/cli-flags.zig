const std = @import("std");

/// Initializes the command-line flags.
const CliFlags = struct {
    args: []const u8,
    allocator: std.mem.Allocator,

    const Self = @This();
    
    /// Initializes the command-line flags.
    pub fn init(allocator: std.mem.Allocator) !CliFlags {
        Self.args = try std.process.argsAlloc(allocator);
    }
    
    /// Frees the memory allocated for the command-line arguments.
    pub fn argsFree(self: *Self) {
        std.process.argsFree(self.allocator, self.args);
    }
}
