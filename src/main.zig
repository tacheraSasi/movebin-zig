const std = @import("std");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();

    var args = std.process.args();
    defer args.deinit();

    while (args.next()) |arg| {
        std.debug.print("Arg: {s}\n", .{arg});
    }
}
