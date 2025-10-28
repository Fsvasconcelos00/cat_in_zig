const std = @import("std");

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

    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };
    defer file.close();

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

    var reader_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&reader_buf);
    const ioreader: *std.Io.Reader = &file_reader.interface;

    while (true) {
        const line = ioreader.takeDelimiterInclusive('\n') catch break;
        std.debug.print("{s}", .{line});
    }
}
