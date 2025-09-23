# zprint

Thread-safe print utilities for Zig CLI applications with formatted printing to stdout and stderr.

## Features

- **Thread-safe**: Uses recursive mutexes for concurrent access
- **Formatted printing**: Supports all Zig format specifiers
- **Explicit error handling**: Choose between error-returning and error-ignoring variants
- **Flexible**: Generic `WriterConfig` allows custom file handles with their own mutexes
- **Auto-buffering**: Internal buffering with automatic flushing
- **Cross-platform**: Handles Windows/Unix differences automatically

## Installation

Add zprint to your project using `zig fetch`:

```bash
zig fetch --save https://github.com/sivel/zprint/archive/v0.1.0.tar.gz
```

Then in your `build.zig`, add the dependency:

```zig
const zprint = b.dependency("zprint", .{});
exe.root_module.addImport("zprint", zprint.module("zprint"));
```

## Usage

### Basic printing

```zig
const zprint = @import("zprint");

// Print to stdout with error handling
try zprint.stdout("Hello {s}! Number: {d}\n", .{ "world", 42 });

// Print to stderr with error handling
try zprint.stderr("Error: {s}\n", .{"something went wrong"});
```

### Debug printing (ignores errors)

```zig
// Debug versions that silently ignore errors
zprint.debug.stdout("Debug message to stdout\n", .{});
zprint.debug.stderr("Debug message to stderr\n", .{});
```

### Custom writer configurations

```zig
const std = @import("std");
const zprint = @import("zprint");

// Example: Custom log file writer
var log_file = try std.fs.cwd().createFile("app.log", .{});
defer log_file.close();

var log_mutex = std.Thread.Mutex.Recursive.init;
var log_buffer: [1024]u8 = undefined;
var log_file_writer = log_file.writer(&log_buffer);

const log_config = zprint.WriterConfig{
    .mutex = &log_mutex,
    .writer = &log_file_writer.interface,
};

// Use the custom config
try zprint.print(log_config, "Log entry: {s}\n", .{"custom message"});
```

### Testing with buffer capture

```zig
const std = @import("std");
const zprint = @import("zprint");

// Capture output to a buffer for testing
var output_buffer: [512]u8 = undefined;
var test_mutex = std.Thread.Mutex.Recursive.init;
var test_writer = std.Io.Writer.fixed(output_buffer[0..]);

const test_config = zprint.WriterConfig{
    .mutex = &test_mutex,
    .writer = &test_writer,
};

try zprint.print(test_config, "Test: {d}\n", .{42});

// Verify output
const written = output_buffer[0..test_writer.end];
// written contains: "Test: 42\n"
```

## API Reference

### Main Functions

- `stdout(fmt, args) !void` - Print to stdout with error handling
- `stderr(fmt, args) !void` - Print to stderr with error handling
- `print(config, fmt, args) !void` - Core function using a WriterConfig (thread-safe, with flushing)

### Debug Functions (error-ignoring)

- `debug.stdout(fmt, args) void` - Print to stdout, ignore errors
- `debug.stderr(fmt, args) void` - Print to stderr, ignore errors

### Types

- `WriterConfig` - Configuration struct containing:
  - `mutex: *std.Thread.Mutex.Recursive` - Mutex for thread safety
  - `writer: *std.Io.Writer` - The writer interface to use

## Why zprint?

Zig's standard library provides `std.debug.print` for debugging (stderr only) but lacks a higher level stdout printing solution for CLI applications. zprint fills this gap by providing:

1. **Proper stdout support** - Unlike `std.debug.print` which only goes to stderr
2. **Thread safety** - Safe for concurrent use across threads
3. **Error handling** - Choose explicit error handling or error-ignoring variants
4. **Flexibility** - Works with any writer, not just stdout/stderr

## License

MIT License - see LICENSE file for details.