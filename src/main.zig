const std = @import("std");
const heap = std.heap;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const bin_path = args[1];// ignoring the first arg which is the program name
    std.debug.print("Binary Path: {s}\n", .{bin_path});

    for (args) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
