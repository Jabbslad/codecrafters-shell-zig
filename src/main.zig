const std = @import("std");

const Command = enum {
    exit,
    echo,
    type,
    pwd,
    cd,
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

        var tokens = std.mem.splitScalar(u8, user_input, ' ');
        var commands = std.ArrayList([]const u8).init(allocator);
        defer commands.deinit();
        while (tokens.next()) |token| {
            try commands.append(token);
        }

        const command_maybe = std.meta.stringToEnum(Command, commands.items[0]);
        if (command_maybe) |command| {
            switch (command) {
                .exit => {
                    std.process.exit(0);
                },
                .echo => {
                    const joined = try std.mem.join(allocator, " ", commands.items[1..]);
                    defer allocator.free(joined);
                    try stdout.print("{s}\n", .{joined});
                },
                .type => {
                    const comm = commands.items[1];
                    if (is_builtin(comm)) |_| {
                        try stdout.print("{s} is a shell builtin\n", .{comm});
                    } else {
                        if (try check_path(allocator, comm)) |p| {
                            try stdout.print("{s} is {s}\n", .{ comm, p });
                        } else {
                            try stdout.print("{s}: not found\n", .{comm});
                        }
                    }
                },
                .pwd => {
                    var buff: [1024]u8 = undefined;
                    _ = try std.fs.cwd().realpath(".", &buff);
                    try stdout.print("{s}\n", .{buff});
                },
                .cd => {
                    std.posix.chdir(commands.items[1]) catch {
                        try stdout.print("cd: {s}: No such file or directory\n", .{commands.items[1]});
                        continue;
                    };
                    const path = try std.fs.realpathAlloc(allocator, ".");
                    defer allocator.free(path);
                    try stdout.print("{s}\n", .{path});
                },
            }
        } else {
            if (try check_path(allocator, commands.items[0])) |_| {
                try run_program(&commands, allocator);
            } else {
                try stdout.print("{s}: command not found\n", .{commands.items[0]});
            }
        }
    }
}

fn is_builtin(command: []const u8) ?Command {
    return std.meta.stringToEnum(Command, command);
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

fn run_program(commands: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    var child = std.process.Child.init(commands.*.items, allocator);
    _ = try child.spawnAndWait();
}
