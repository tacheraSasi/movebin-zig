const std = @import("std");
const heap = std.heap;

pub fn main() !void {
    const gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    while (args.next()) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
