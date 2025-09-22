/// Robust print utilities for Zig CLI applications
/// Based on std.debug.print implementation but adapted for stdout/stderr flexibility
const std = @import("std");
const Writer = std.Io.Writer;

/// Configuration for a thread-safe writer
pub const WriterConfig = struct {
    mutex: *std.Thread.Mutex.Recursive,
    writer: *Writer,
};

// Pre-configured stdout setup with proper buffer
var stdout_mutex = std.Thread.Mutex.Recursive.init;
var stdout_buffer: [1024]u8 = undefined;
var stdout_file_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout_config = WriterConfig{
    .mutex = &stdout_mutex,
    .writer = &stdout_file_writer.interface,
};

// Pre-configured stderr setup with proper buffer
var stderr_mutex = std.Thread.Mutex.Recursive.init;
var stderr_buffer: [1024]u8 = undefined;
var stderr_file_writer = std.fs.File.stderr().writer(&stderr_buffer);
const stderr_config = WriterConfig{
    .mutex = &stderr_mutex,
    .writer = &stderr_file_writer.interface,
};

/// Core print function using a writer configuration with explicit error handling. Thread-safe.
/// Flushes the writer before returning.
pub fn print(config: WriterConfig, comptime fmt: []const u8, args: anytype) !void {
    config.mutex.lock();
    defer config.mutex.unlock();
    try config.writer.print(fmt, args);
    try config.writer.flush();
}

/// Print to stdout with explicit error handling. Thread-safe.
/// Uses a 1024-byte buffer for formatted printing which is flushed before this
/// function returns.
pub fn stdout(comptime fmt: []const u8, args: anytype) !void {
    try print(stdout_config, fmt, args);
}

/// Print to stderr with explicit error handling. Thread-safe.
/// Uses a 1024-byte buffer for formatted printing which is flushed before this
/// function returns.
pub fn stderr(comptime fmt: []const u8, args: anytype) !void {
    try print(stderr_config, fmt, args);
}

/// Debug printing functions that silently ignore errors, similar to std.debug.print
pub const debug = struct {
    /// Print to stdout, silently returning on failure. Thread-safe.
    /// Uses a 1024-byte buffer for formatted printing which is flushed before this
    /// function returns.
    pub fn stdout(comptime fmt: []const u8, args: anytype) void {
        print(stdout_config, fmt, args) catch return;
    }

    /// Print to stderr, silently returning on failure. Thread-safe.
    /// Uses a 1024-byte buffer for formatted printing which is flushed before this
    /// function returns.
    pub fn stderr(comptime fmt: []const u8, args: anytype) void {
        print(stderr_config, fmt, args) catch return;
    }
};

// Tests
const testing = std.testing;

test "print function with buffer capture" {
    var output_buffer: [512]u8 = undefined;
    var test_mutex = std.Thread.Mutex.Recursive.init;
    var test_writer = std.Io.Writer.fixed(output_buffer[0..]);
    const config = WriterConfig{
        .mutex = &test_mutex,
        .writer = &test_writer,
    };

    // Test our print function
    try print(config, "Hello {s}! Number: {d}\n", .{ "world", 42 });

    // Get the written data from the buffer
    const written = output_buffer[0..test_writer.end];
    const expected = "Hello world! Number: 42\n";
    try testing.expectEqualStrings(expected, written);
}

test "multiple format types" {
    var output_buffer: [512]u8 = undefined;
    var test_mutex = std.Thread.Mutex.Recursive.init;
    var test_writer = std.Io.Writer.fixed(output_buffer[0..]);
    const config = WriterConfig{
        .mutex = &test_mutex,
        .writer = &test_writer,
    };

    // Test various format types using our print function
    try print(config, "String: {s}\n", .{"test"});
    try print(config, "Decimal: {d}\n", .{42});
    try print(config, "Hex: {x}\n", .{255});

    const written = output_buffer[0..test_writer.end];
    const expected = "String: test\nDecimal: 42\nHex: ff\n";
    try testing.expectEqualStrings(expected, written);
}

test "WriterConfig structure validation" {
    var output_buffer: [256]u8 = undefined;
    var test_mutex = std.Thread.Mutex.Recursive.init;
    var test_writer = std.Io.Writer.fixed(output_buffer[0..]);
    const config = WriterConfig{
        .mutex = &test_mutex,
        .writer = &test_writer,
    };

    // Verify the structure is valid and compiles
    try testing.expect(@TypeOf(config.mutex) == *std.Thread.Mutex.Recursive);
    try testing.expect(@TypeOf(config.writer) == *Writer);
}

test "empty and edge case formats" {
    var output_buffer: [256]u8 = undefined;
    var test_mutex = std.Thread.Mutex.Recursive.init;
    var test_writer = std.Io.Writer.fixed(output_buffer[0..]);
    const config = WriterConfig{
        .mutex = &test_mutex,
        .writer = &test_writer,
    };

    // Test empty format string
    try print(config, "", .{});
    try testing.expect(test_writer.end == 0);

    // Test just newline
    try print(config, "\n", .{});
    const written = output_buffer[0..test_writer.end];
    try testing.expectEqualStrings("\n", written);
}
