const std = @import("std");

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        // TODO: Handle user input
        const space = std.mem.indexOf(u8, user_input, " ").?;
        const command = user_input[0..space];
        const args = user_input[space + 1 ..];
        if (std.mem.eql(u8, command, "exit")) {
            std.process.exit(try std.fmt.parseInt(u8, user_input[space + 1 ..], 10));
        } else if (std.mem.eql(u8, command, "echo")) {
            try stdout.print("{s}\n", .{args});
        } else {
            try stdout.print("{s}: command not found\n", .{command});
        }
    }
}
