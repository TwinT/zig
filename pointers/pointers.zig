const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;

pub fn main() void {
    const array = [3]u8{ 1, 2, 3 };
    const comptime_slice = array[0..];

    var n: u8 = 0;
    var m: u8 = 2;
    const slice = array[n..m];

    n += 1;
    m -= 1;
    const var_slice = array[n..m];

    std.debug.print("type of array = {}\n", .{@TypeOf(array)});
    std.debug.print("type of &array = {}\n", .{@TypeOf(&array)});
    std.debug.print("type of &[_]{{1,2,3}} = {}\n", .{@TypeOf([_]u8{ 1, 2, 3 })});
    std.debug.print("type of comptime_slice = {}\n", .{@TypeOf(comptime_slice)});
    std.debug.print("type of slice = {}\n", .{@TypeOf(slice)});
    std.debug.print("type of var_slice = {}\n", .{@TypeOf(var_slice)});
}

test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    try expect(c == 12);
    const d: f32 = b;
    _ = d;
}

test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}

test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
