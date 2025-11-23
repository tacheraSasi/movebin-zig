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

    const bin_path = args[1]; // ignoring the first arg which is the program name

    const exists = try utils.FileExists(bin_path);

    if (!exists) {
        std.debug.print("File does not exist: {s}\n", .{bin_path});
        return;
    }

    const dest_path = try std.fs.path.join(allocator, &.{ "/usr/local/bin", std.fs.path.basename(bin_path) });
    defer allocator.free(dest_path);

    const does_dest_exist = try utils.FileExists(dest_path);
    if (does_dest_exist) {
        const overwrite = try utils.askYesNo("Destination file already exists. Do you want to overwrite it?", false);
        if (!overwrite) {
            return;
        }
    }

    std.debug.print("Destination Path: {s}\n", .{dest_path});
}
