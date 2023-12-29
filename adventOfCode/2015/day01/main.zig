const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const Result = struct {
    result: i32,
    position: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 2) {
        // resolve pathname
        const pathname = args[1];

        // read file
        const fd = std.fs.cwd().openFile(pathname, .{ .mode = .read_only }) catch |err| {
            print("{s}:{s}\n", .{ pathname, @errorName(err) });
            return;
        };

        defer fd.close();

        const directions = try fd.readToEndAlloc(allocator, std.math.maxInt(u32));
        defer allocator.free(directions);

        const result = solve(directions);
        print("Result: {}\n", .{result.result});
        print("Position: {}\n", .{result.position});
    } else {
        print("Usage: ./main FILE\n", .{});
    }
}

pub fn solve(directions: []const u8) Result {
    var result: i32 = 0;
    var position: usize = 0;

    for (directions, 1..) |dir, i| {
        switch (dir) {
            '(' => result += 1,
            ')' => result -= 1,
            else => unreachable,
        }
        if (position == 0 and result < 0) {
            position = i;
        }
    }
    return .{ .result = result, .position = position };
}

test "test0-0" {
    try expect(0 == solve("(())"));
    try expect(0 == solve("()()"));
}

test "test3-0" {
    try expect(3 == solve("((("));
    try expect(3 == solve("(()(()("));
}

test "test3-1" {
    try expect(3 == solve("(()(()("));
    try expect(3 == solve("))((((("));
}

test "test-1-0" {
    try expect(-1 == solve("())"));
    try expect(-1 == solve("))("));
}

test "test-3-0" {
    try expect(-3 == solve(")))"));
    try expect(-3 == solve(")())())"));
}
