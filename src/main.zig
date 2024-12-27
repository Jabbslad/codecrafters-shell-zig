const std = @import("std");

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var commands = std.mem.splitScalar(u8, user_input, ' ');
        const command = commands.first();
        const args = commands.rest();

        if (std.mem.eql(u8, command, "exit")) {
            std.process.exit(try std.fmt.parseInt(u8, args, 10));
        } else if (std.mem.eql(u8, command, "echo")) {
            try stdout.print("{s}\n", .{args});
        } else if (std.mem.eql(u8, command, "type")) {
            var args2 = std.mem.splitScalar(u8, args, ' ');
            const arg1 = args2.first();
            if (is_builtin(arg1)) {
                try stdout.print("{s}: is a shell builtin\n", .{arg1});
            } else {
                try stdout.print("{s}: not found\n", .{arg1});
            }
        } else {
            try stdout.print("{s}: command not found\n", .{command});
        }
    }
}

fn is_builtin(command: []const u8) bool {
    return std.mem.eql(u8, command, "type") or std.mem.eql(u8, command, "exit") or std.mem.eql(u8, command, "echo");
}
