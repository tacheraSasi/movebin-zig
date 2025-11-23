const std = @import("std");
const heap = std.heap;
const utils = @import("utils.zig");

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <binary_path> [args...]\n", .{args[0]});
        return;
    }

    const bin_path = args[1];// ignoring the first arg which is the program name
    std.debug.print("Binary Path: {s}\n", .{bin_path});

    const exists = try utils.FileExists(allocator, bin_path);

    if (!exists) {
        std.debug.print("File does not exist: {s}\n", .{bin_path});
        return;
    }
    for (args) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
