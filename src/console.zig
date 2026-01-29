
const std = @import("std");
const Allocator = std.mem.Allocator;

///A struct that allows console reading and writing without boilerplate.
///usage:
/// 
/// var console:Console = undefined;
/// console.init(&write_buffer, &read_buffer);
/// 
/// Use console.writer or console.reader for all methods.
pub const Console = struct {
    out_f:std.fs.File,
    fw:std.fs.File.Writer,
    writer:*std.Io.Writer,

    in_file:std.fs.File,
    fr:std.fs.File.Reader,
    reader:*std.Io.Reader,

    const Self = @This();

    pub fn init(self:*Self, write_buffer:[]u8, read_buffer:[]u8) void {
        self.out_f = std.fs.File.stdout();
        self.fw = self.out_f.writer(write_buffer);
        self.writer = &self.fw.interface;

        self.in_file = std.fs.File.stdin();
        self.fr = self.in_file.reader(read_buffer);
        self.reader = &self.fr.interface;
    }

    ///Prints to the console immediately.
    ///Use this when you want to see output now.
    pub fn printLine(self:*const Self, comptime fmt:[]const u8, args:anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.print("\n", .{});
        try self.writer.flush();
    }
    ///Prints to the console immediately.
    ///Use this when you want to see output now.
    pub fn print(self:*const Self, comptime fmt:[]const u8, args:anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.flush();
    }
    ///Prints to the console immediately.
    ///Use this when you want to see output now.
    pub fn printANewLine(self:*const Self) !void {
        try self.writer.print("\n", .{});
        try self.writer.flush();
    }
    ///Writes to buffer only, use flush to see it in the console.
    ///Use this when you want to add many things to the buffer and print them all at once with flush.
    pub fn writeLine(self:*const Self, comptime fmt:[]const u8, args:anytype) !void {
        try self.writer.print(fmt, args);
        try self.writer.print("\n", .{});
    }
    ///Writes to buffer only, use flush to see it in the console.
    ///Use this when you want to add many things to the buffer and print them all at once with flush.
    pub fn write(self:*const Self, comptime fmt:[]const u8, args:anytype) !void {
        try self.writer.print(fmt, args);
    }
    ///Prints to the console immediately.
    ///Use this when you want to see output now.
    pub fn writeANewLine(self:*const Self) !void {
        try self.writer.print("\n", .{});
    }
    ///Prints the buffer to the console
    pub fn flush(self:*const Self) !void {
        try self.writer.flush();
    }

    /// Reads until a new line character.
    /// Removes '\r'
    pub fn readLine(self:*const Self) ![]u8 {
        var line:[]u8 = try self.reader.takeDelimiterExclusive('\n');

        // Handle optional CR before LF (Windows-style)
        if (line.len > 0 and line[line.len - 1] == '\r') {
            line = line[0 .. line.len - 1];
        }

        return line;
    }

    /// Fills the buffer such that it contains at least `n` bytes, without
    /// advancing the seek position.
    ///
    /// Returns `error.EndOfStream` if and only if there are fewer than `n` bytes
    /// remaining.
    ///
    /// If the end of stream is not encountered, asserts buffer capacity is at
    /// least `n`.
    pub fn fill(self:*const Self, n:usize) !void {
        try self.reader.fill(n);
    }

    /// Returns the next `len` bytes from the stream, filling the buffer as
    /// necessary.
    ///
    /// Invalidates previously returned values from `peek`.
    ///
    /// Asserts that the `Reader` was initialized with a buffer capacity at
    /// least as big as `len`.
    ///
    /// If there are fewer than `len` bytes left in the stream, `error.EndOfStream`
    /// is returned instead.
    pub fn peek(self:*const Self, n:usize) ![]u8 {
        return try self.reader.peek(n);
    }
    /// Returns the next byte from the stream or returns `error.EndOfStream`.
    ///
    /// Does not advance the seek position.
    ///
    /// Asserts the buffer capacity is nonzero.
    pub fn peekByte(self:*const Self) !u8 {
        return try self.reader.peekByte();
    }
    /// Reads 1 byte from the stream or returns `error.EndOfStream`.
    ///
    /// Asserts the buffer capacity is nonzero.
    pub fn readByte(self:*const Self) !u8 {
        return try self.reader.takeByte();
    }
};
