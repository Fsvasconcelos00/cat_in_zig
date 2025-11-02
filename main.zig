const std = @import("std");

const zig_cat_version = "0.1.0";

var number_option: bool = false;
var number_nonblank_option: bool = false;

fn help() !void {
    std.debug.print("Usage: cat [filename] [options]\n", .{});
    std.debug.print("Options:\n", .{});
    std.debug.print("--number: Adds the line numbers before the line contents\n", .{});
    std.debug.print("--number-nonblank: Adds the line numbers before the line contents, except for empty lines\n", .{});
    std.debug.print("--help: Shows this helper\n", .{});
    std.debug.print("--version: Shows cat in zig version\n", .{});
}

fn version() !void {
    std.debug.print("Zig cat is currently on version {s}\n", .{zig_cat_version});
}

pub fn printFromStdin() !void {
    // .readerStreaming is used for stdin/stdout/stderr streaming resources.
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader_wrapper = std.fs.File.stdin().readerStreaming(&stdin_buffer);
    const reader: *std.Io.Reader = &stdin_reader_wrapper.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer_wrapper = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer_wrapper.interface;

    try stdout.writeAll("");
    try stdout.flush(); // To ensure prompt appears before input
    var line_number: u32 = 0;

    while (true) {
        const line = reader.takeDelimiterInclusive('\n') catch break;

        try stdout.writeAll("");
        if ((number_nonblank_option == true) and (std.mem.eql(u8, line, "\n"))) {
            // Do not increase line_number
            try stdout.print("{s}", .{line});
        } else {
            line_number += 1;
            try stdout.print("{} {s}", .{ line_number, line });
        }
        try stdout.writeAll("");
        try stdout.flush();
    }
}

fn printFile(filename: []const u8) !void {
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.log.err("Failed to open file: {s} {s}", .{ filename, @errorName(err) });
        return;
    };
    defer file.close();

    var reader_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&reader_buf);
    const ioreader: *std.Io.Reader = &file_reader.interface;
    var line_number: u32 = 0;

    while (true) {
        const line = ioreader.takeDelimiterInclusive('\n') catch break;
        if ((number_nonblank_option == true) and (std.mem.eql(u8, line, "\n"))) {
            // Do not increase line_number
            std.debug.print("{s}", .{line});
        } else {
            line_number += 1;
            std.debug.print("{} {s}", .{ line_number, line });
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var stdin_option: bool = false;
    var filename_array: [10][]const u8 = undefined; // up to 10 filenames
    var file_size: u8 = 0;

    if (args.len < 2) {
        try help();
        return;
    } else if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "--help")) {
            try help();
            return;
        } else if (std.mem.eql(u8, args[1], "--version")) {
            try version();
            return;
        } else if (std.mem.eql(u8, args[1], "-")) {
            try printFromStdin();
            return;
        } else {
            try printFile(args[1]);
            return;
        }
    } else {
        for (1..(args.len)) |arg_index| {
            if (std.mem.eql(u8, args[arg_index], "--number")) {
                number_option = true;
            } else if (std.mem.eql(u8, args[arg_index], "--number-nonblank")) {
                number_nonblank_option = true;
            } else if (std.mem.eql(u8, args[arg_index], "-")) {
                stdin_option = true;
            } else {
                filename_array[file_size] = args[arg_index];
                file_size += 1;
            }
        }
    }

    for (0..file_size) |file_index| {
        try printFile(filename_array[file_index]);
    }

    if (stdin_option == true) {
        try printFromStdin();
    }
}
