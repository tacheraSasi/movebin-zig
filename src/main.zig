const std = @import("std");
const heap = std.heap;
const utils = @import("utils.zig");
const string: type = []const u8;
pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        try printer("Usage: sudo movebin <binary_path> [args...]\n", .{});
        return;
    }
    const bin_path = args[1]; // ignoring the first arg which is the program name
    const exists = try utils.fileExists(bin_path);
    if (!exists) {
        try printer("File does not exist: {s}\n", .{bin_path});
        return;
    }
    const dest_path = try std.fs.path.join(allocator, &.{ "/usr/local/bin", std.fs.path.basename(bin_path) });
    defer allocator.free(dest_path);
    const does_dest_exist = try utils.fileExists(dest_path);
    if (does_dest_exist) {
        try printer("File already exists at destination: {s}\n", .{dest_path});
        const overwrite = utils.isForceFlagEnabled(args);
        if (!overwrite) {
            const wantToOverride = try utils.askYesNo("Do you want to override", false);
            if (!wantToOverride) {
                try printer("Aborting installation to avoid overwriting existing file.\n", .{});
                return;
            }
        }
        try printer("Force flag enabled.\n", .{});
        try printer("Overwriting existing file at destination: {s}\n", .{dest_path});
        try utils.deleteExistingBin(dest_path);
    }
    try utils.copyToDestination(bin_path, dest_path);
    try printer("Successfully moved binary to {s}\n", .{dest_path});
}

fn printer(comptime fmt:[]const u8, args: anytype) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.print(fmt, args);
    try stdout.flush();
}