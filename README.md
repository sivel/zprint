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
// Create your own writer config
var custom_mutex = std.Thread.Mutex.Recursive.init;
var custom_file_writer: std.fs.File.Writer = .{
    .interface = std.fs.File.Writer.initInterface(&.{}),
    .file = .stdout(),
    .mode = .streaming,
};
const custom_config = zprint.WriterConfig{
    .mutex = &custom_mutex,
    .file_writer = &custom_file_writer,
    .file = .stdout(),
};

try zprint.printConfig(custom_config, "Custom config: {s}\n", .{"works!"});
```

### Generic writer printing

```zig
// Use with any writer
const writer = lockWriterConfig(custom_config, &buffer);
defer unlockWriterConfig(custom_config);
try zprint.print(writer, "Generic printing: {}\n", .{value});
```

## API Reference

### Main Functions

- `stdout(fmt, args) !void` - Print to stdout with error handling
- `stderr(fmt, args) !void` - Print to stderr with error handling
- `printConfig(config, fmt, args) !void` - Print using custom writer config
- `print(writer, fmt, args) !void` - Core function for any writer

### Debug Functions (error-ignoring)

- `debug.stdout(fmt, args) void` - Print to stdout, ignore errors
- `debug.stderr(fmt, args) void` - Print to stderr, ignore errors

### Writer Management

- `WriterConfig` - Configuration struct for custom writers
- `lockWriterConfig(config, buffer) *Writer` - Lock a writer for use
- `unlockWriterConfig(config) void` - Unlock a writer

## Why zprint?

Zig's standard library provides `std.debug.print` for debugging (stderr only) but lacks a higher level stdout printing solution for CLI applications. zprint fills this gap by providing:

1. **Proper stdout support** - Unlike `std.debug.print` which only goes to stderr
2. **Thread safety** - Safe for concurrent use across threads
3. **Error handling** - Choose explicit error handling or error-ignoring variants
4. **Flexibility** - Works with any writer, not just stdout/stderr

## License

MIT License - see LICENSE file for details.