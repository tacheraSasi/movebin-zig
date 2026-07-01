const std = @import("std");
const Allocator = std.mem.Allocator;

/// A struct that allows console reading and writing without boilerplate.
/// 
/// Usage:
/// ```
/// var console: Console = undefined;
/// console.init(init.io, &write_buffer, &read_buffer);
/// 
/// Use console.writer or console.reader for all methods.
/// ```
pub const Console = struct {
    io: std.Io,                    // Required in 0.16+
    out_f: std.Io.File,
    fw: std.Io.File.Writer,        // Concrete writer (holds buffer + state)
    writer: *std.Io.Writer,        // Interface
    in_file: std.Io.File,
    fr: std.Io.File.Reader,        // Concrete reader
    reader: *std.Io.Reader,        // Interface

    const Self = @This();

    /// Initialize with an Io instance (e.g. from `init.io` in juicy main)
    pub fn init(self: *Self, io: std.Io, write_buffer: []u8, read_buffer: []u8) void {
        self.io = io;

        self.out_f = std.Io.File.stdout();
        self.fw = self.out_f.writer(io, write_buffer);   // Note: passes io + buffer
        self.writer = &self.fw.interface;

        self.in_file = std.Io.File.stdin();
        self.fr = self.in_file.reader(io, read_buffer);
        self.reader = &self.fr.interface;
    }

    /// Prints to the console immediately.
    pub fn printLine(self: *const Self, comptime fmt: []const u8, args: anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.print("\n", .{});
        try self.writer.flush();
    }

    /// Prints to the console immediately.
    pub fn print(self: *const Self, comptime fmt: []const u8, args: anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.flush();
    }

    pub fn printANewLine(self: *const Self) !void {
        try self.writer.print("\n", .{});
        try self.writer.flush();
    }

    /// Writes to buffer only (flush later).
    pub fn writeLine(self: *const Self, comptime fmt: []const u8, args: anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.print("\n", .{});
    }

    pub fn write(self: *const Self, comptime fmt: []const u8, args: anytype) !void {
        try self.writer.print(fmt, args);
    }

    pub fn writeANewLine(self: *const Self) !void {
        try self.writer.print("\n", .{});
    }

    pub fn flush(self: *const Self) !void {
        try self.writer.flush();
    }

    /// Reads until a new line character. Removes trailing '\r' (Windows).
    pub fn readLine(self: *const Self) ![]u8 {
        var line: []u8 = try self.reader.takeDelimiterExclusive('\n');
        // Handle optional CR before LF
        if (line.len > 0 and line[line.len - 1] == '\r') {
            line = line[0 .. line.len - 1];
        }
        return line;
    }

    // The rest of the methods (fill, peek, peekByte, readByte) stay almost identical
    pub fn fill(self: *const Self, n: usize) !void {
        try self.reader.fill(n);
    }

    pub fn peek(self: *const Self, n: usize) ![]u8 {
        return try self.reader.peek(n);
    }

    pub fn peekByte(self: *const Self) !u8 {
        return try self.reader.peekByte();
    }

    pub fn readByte(self: *const Self) !u8 {
        return try self.reader.takeByte();
    }
};