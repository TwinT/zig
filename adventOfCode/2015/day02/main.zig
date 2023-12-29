const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const Result = struct {
    paper: u32 = 0,
    ribbon: u32 = 0,
};

const Dimension = struct {
    w: u32,
    l: u32,
    h: u32,

    fn equal(self: Dimension, other: Dimension) bool {
        return self.h == other.h and self.l == other.l and self.w == other.w;
    }
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
        var buf_reader = std.io.bufferedReader(fd.reader());
        const in_stream = buf_reader.reader();

        var total: Result = .{};
        while (try in_stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
            defer allocator.free(line);
            const result = solve(line);

            total.paper += result.paper;
            total.ribbon += result.ribbon;
        }

        print("Result:\npaper:{}\nribbon:{}\n", .{ total.paper, total.ribbon });
    } else {
        print("Usage: ./main FILE\n", .{});
    }
}

pub fn solve(dimensions: []const u8) Result {
    const dim = parse(dimensions);
    var paper: u32 = 0;
    var ribbon: u32 = 0;
    var faces: [3]u32 = undefined;
    var perimeters: [3]u32 = undefined;

    faces[0] = dim.h * dim.l;
    faces[1] = dim.h * dim.w;
    faces[2] = dim.l * dim.w;

    perimeters[0] = 2 * (dim.h + dim.l);
    perimeters[1] = 2 * (dim.h + dim.w);
    perimeters[2] = 2 * (dim.l + dim.w);

    var min: u32 = std.math.maxInt(u32);
    for (faces) |face| {
        paper += 2 * face;
        if (face < min) {
            min = face;
        }
    }

    paper += min;

    min = std.math.maxInt(u32);
    for (perimeters) |perimeter| {
        if (perimeter < min) {
            min = perimeter;
        }
    }
    ribbon = min + dim.h * dim.l * dim.w;

    return .{ .paper = paper, .ribbon = ribbon };
}

fn parse(line: []const u8) Dimension {
    var it = std.mem.split(u8, line, "x");
    var dim: [3]u32 = undefined;
    var i: u32 = 0;
    while (it.next()) |x| {
        dim[i] = std.fmt.parseInt(u32, x, 10) catch 0;
        i += 1;
    }
    return .{ .w = dim[0], .l = dim[1], .h = dim[2] };
}

test "parse" {
    try expect(parse("2x3x4").equal(.{ .w = 2, .l = 3, .h = 4 }));
}

test "test_paper1" {
    try std.testing.expectEqual(@as(u32, 58), solve("2x3x4").paper);
}

test "test_paper2" {
    try std.testing.expectEqual(@as(u32, 43), solve("1x1x10").paper);
}

test "test_ribbon1" {
    try std.testing.expectEqual(@as(u32, 34), solve("2x3x4").ribbon);
}

test "test_ribbon2" {
    try std.testing.expectEqual(@as(u32, 14), solve("1x1x10").ribbon);
}
