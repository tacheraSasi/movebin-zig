const std = @import("std");
const utils = @import("utils.zig");
const Console = @import("console.zig").Console;

const heap = std.heap;
const string: type = []const u8;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var write_buffer: [1024]u8 = undefined;
    var read_buffer: [1024]u8 = undefined;
    var console: Console = undefined;
    console.init(&write_buffer, &read_buffer);

    if (args.len < 2) {
        try console.printLine("Usage: sudo movebin <binary_path> [args...]\n", .{});
        return;
    }
    const bin_path = args[1]; // ignoring the first arg which is the program name
    const exists = try utils.fileExists(bin_path);
    if (!exists) {
        try console.printLine("File does not exist: {s}\n", .{bin_path});
        return;
    }
    const dest_path = try std.fs.path.join(allocator, &.{ "/usr/local/bin", std.fs.path.basename(bin_path) });
    defer allocator.free(dest_path);
    const does_dest_exist = try utils.fileExists(dest_path);
    if (does_dest_exist) {
        try console.printLine("File already exists at destination: {s}\n", .{dest_path});
        const overwrite = utils.isForceFlagEnabled(args);
        if (!overwrite) {
            const wantToOverride = try utils.askYesNo(console,"Do you want to override", false);
            if (!wantToOverride) {
                try console.printLine("Aborting installation to avoid overwriting existing file.\n", .{});
                return;
            }
        }
        try console.printLine("Force flag enabled.\n", .{});
        try console.printLine("Overwriting existing file at destination: {s}\n", .{dest_path});
        try utils.deleteExistingBin(dest_path);
    }
    try utils.copyToDestination(bin_path, dest_path);
    try console.printLine("Successfully moved binary to {s}\n", .{dest_path});
}
