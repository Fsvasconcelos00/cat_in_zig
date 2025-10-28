const std = @import("std");

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
        if (std.mem.eql(u8, arg, "--number")) {
            number_option = true;
        } else if (std.mem.eql(u8, arg, "--number-nonblank")) {
            number_nonblank_option = true;
        } else if (std.mem.eql(u8, arg, "--help")) {
            help_option = true;
        } else if (std.mem.eql(u8, arg, "--version")) {
            version_option = true;
        }
    }

    var reader_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&reader_buf);
    const ioreader: *std.Io.Reader = &file_reader.interface;

    while (true) {
        // break on any read error/EOF; adjust error handling if you need to distinguish errors
        const line = ioreader.takeDelimiterInclusive('\n') catch break;
        std.debug.print("{s}", .{line});
    }
}
