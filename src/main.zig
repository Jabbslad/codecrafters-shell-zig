const std = @import("std");

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;
    var command: []u8 = undefined;
    var args: ?[]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        // TODO: Handle user input
        if (std.mem.indexOf(u8, user_input, " ")) |i| {
            command = user_input[0..i];
            args = user_input[i + 1 ..];
        } else {
            command = user_input;
            args = null;
        }
        if (std.mem.eql(u8, command, "exit")) {
            std.process.exit(try std.fmt.parseInt(u8, args.?, 10));
        } else if (std.mem.eql(u8, command, "echo")) {
            try stdout.print("{s}\n", .{args.?});
        } else {
            try stdout.print("{s}: command not found\n", .{command});
        }
    }
}
