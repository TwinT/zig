const std = @import("std");
const print = std.debug.print;
const expectEqual = std.testing.expectEqual;

const Result = struct {
    result: u32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 3) {
        // resolve pathname
        const pathname = args[1];
        const santas: u8 = try std.fmt.parseInt(u8, args[2], 10);

        // read file
        const fd = std.fs.cwd().openFile(pathname, .{ .mode = .read_only }) catch |err| {
            print("{s}:{s}\n", .{ pathname, @errorName(err) });
            return;
        };

        defer fd.close();

        const directions = try fd.readToEndAlloc(allocator, std.math.maxInt(u32));
        defer allocator.free(directions);

        const result = solve(allocator, directions, santas);
        print("Result: {}\n", .{result.result});
    } else {
        print("Usage: ./main FILE SANTAS\n", .{});
    }
}

pub fn solve(allocator: std.mem.Allocator, directions: []const u8, santas: u8) Result {
    var map: Map = Map.init(allocator);
    defer map.deinit();

    for (0..santas) |j| {
        var p: Point = .{ .x = 0, .y = 0 };
        map.goto(p);

        for (0..(directions.len / santas)) |i| {
            switch (directions[j + i * santas]) {
                '^' => {
                    map.goto(p.up());
                },
                '<' => {
                    map.goto(p.west());
                },
                '>' => {
                    map.goto(p.east());
                },
                'v' => {
                    map.goto(p.down());
                },
                else => unreachable,
            }
        }
    }

    const result = map.count();
    return .{ .result = result };
}

const Point = struct {
    x: i32,
    y: i32,

    pub fn up(self: *Point) Point {
        self.y += 1;
        return self.*;
    }

    pub fn down(self: *Point) Point {
        self.y -= 1;
        return self.*;
    }

    pub fn east(self: *Point) Point {
        self.x += 1;
        return self.*;
    }

    pub fn west(self: *Point) Point {
        self.x -= 1;
        return self.*;
    }
};

const Map = struct {
    hashmap: Hashmap,

    pub const Hashmap = std.AutoHashMap(Point, u32);

    pub fn init(allocator: std.mem.Allocator) Map {
        const map = Map{ .hashmap = Hashmap.init(allocator) };
        return map;
    }

    pub fn goto(self: *Map, p: Point) void {
        const value = self.hashmap.get(p) orelse 0;
        self.hashmap.put(p, value + 1) catch unreachable;
    }

    pub fn sumUp(self: Map) u32 {
        var sum: u32 = 0;
        var it = self.hashmap.iterator();
        while (it.next()) |kv| {
            sum += kv.value_ptr.*;
        }
        return sum;
    }

    pub fn count(self: Map) u32 {
        return self.hashmap.count();
    }

    fn deinit(self: *Map) void {
        self.hashmap.deinit();
    }
};

test "test_east" {
    try expectEqual(@as(u32, 2), solve(std.testing.allocator, ">", 1).result);
}

test "test_square" {
    try expectEqual(@as(u32, 4), solve(std.testing.allocator, "^>v<", 1).result);
}

test "test_updown" {
    try expectEqual(@as(u32, 2), solve(std.testing.allocator, "^v^v^v^v^v", 1).result);
}

test "robo_santa:test_east" {
    try expectEqual(@as(u32, 3), solve(std.testing.allocator, "^v", 2).result);
}

test "robo_santa:test_square" {
    try expectEqual(@as(u32, 3), solve(std.testing.allocator, "^>v<", 2).result);
}

test "robo_santa:test_updown" {
    try expectEqual(@as(u32, 11), solve(std.testing.allocator, "^v^v^v^v^v", 2).result);
}
