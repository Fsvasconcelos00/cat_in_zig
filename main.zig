const std = @import("std");

const zig_cat_version = "0.0.3";

const option_names = [_][]const u8{
    "--number",
    "--number-nonblank",
    "--help",
    "--version",
};

fn match_option(arg: []const u8) ?usize {
    var i: usize = 0;
    while (i < option_names.len) : (i += 1) {
        if (std.mem.eql(u8, arg, option_names[i])) return i;
    }
    return null;
}

fn help() !void {
    std.debug.print("Usage: cat [filename] [options]\n", .{});
    std.debug.print("Options:\n", .{});
    std.debug.print("--number: Adds the line numbers before the line contents\n", .{});
    std.debug.print("--number-nonblank: Adds the line numbers before the line contents, except for empty lines\n", .{});
    std.debug.print("--help: Shows this helper\n", .{});
    std.debug.print("--help: Shows cat in zig version\n", .{});
}

fn version() !void {
    std.debug.print("Zig cat is currently on version {s}\n", .{zig_cat_version});
}

pub fn main() !void {
    var args = std.process.args();
    var number_option: bool = false;
    var number_nonblank_option: bool = false;
    var help_option: bool = false;
    var version_option: bool = false;

    // Skip program path (args[0])
    _ = args.next();

    const filename = args.next() orelse {
        std.debug.print("Missing filename", .{});
        return;
    };

    while (args.next()) |arg| {
        if (match_option(arg)) |id| {
            switch (id) {
                0 => number_option = true,
                1 => number_nonblank_option = true,
                2 => help_option = true,
                3 => version_option = true,
                else => {},
            }
        } else {
            // unknown trailing arg — ignore or handle as needed
        }
    }

    if (help_option == true) {
        try help();
        return;
    } else if (version_option == true) {
        try version();
        return;
    } else {
        const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
            std.log.err("Failed to open file: {s}", .{@errorName(err)});
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
}
