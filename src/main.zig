const std = @import("std");
const heap = std.heap;

pub fn main() !void {
    const gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var args = std.process.argsAlloc(allocator);
    defer args.deinit();

    while (args.next()) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
