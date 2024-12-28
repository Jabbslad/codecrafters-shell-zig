const std = @import("std");

const Command = enum {
    exit,
    echo,
    type,
};

pub fn main() !void {
    // Uncomment this block to pass the first stage
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');

        var commands = std.mem.splitScalar(u8, user_input, ' ');
        const command_raw = commands.first();
        const args = commands.rest();

        const command_maybe = std.meta.stringToEnum(Command, command_raw);
        if (command_maybe) |command| {
            switch (command) {
                .exit => {
                    std.process.exit(0);
                },
                .echo => {
                    try stdout.print("{s}\n", .{args});
                },
                .type => {
                    if (is_builtin(args)) {
                        try stdout.print("{s} is a shell builtin\n", .{args});
                    } else {
                        if (try check_path(allocator, args)) |p| {
                            try stdout.print("{s} is {s}\n", .{ args, p });
                        } else {
                            try stdout.print("{s}: not found\n", .{args});
                        }
                    }
                },
            }
        } else {
            try stdout.print("{s}: command not found\n", .{command_raw});
        }
    }
}

fn is_builtin(command: []const u8) bool {
    return std.meta.stringToEnum(Command, command) != null;
}

fn check_path(allocator: std.mem.Allocator, command: []const u8) !?[]const u8 {
    const path = std.posix.getenv("PATH").?;
    var itr = std.mem.splitScalar(u8, path, ':');
    while (itr.next()) |pathc| {
        const bin = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ pathc, "/", command });
        std.fs.accessAbsolute(bin, .{}) catch continue;
        return bin;
    }
    return null;
}
