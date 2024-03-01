const std = @import("std");

fn insertSort(comptime T: type, begin: [*]T, end: [*]T) void {
    if (begin == end) return;
    var cur: [*]T = begin + 1;
    while (cur != end) : (cur += 1) {
        var sift: [*]T = cur;
        var sift_1: [*]T = cur - 1;
        if (sift[0] < sift_1[0]) {
            const tmp: T = sift[0];
            sift[0] = sift_1[0];
            sift -= 1;
            sift_1 -= 1;
            while (sift != begin and tmp < sift_1[0]) {
                sift[0] = sift_1[0];
                sift -= 1;
                sift_1 -= 1;
            }
            sift[0] = tmp;
        }
    }
    return;
}

test "insertSort" {
    const arr: []u64 = try std.testing.allocator.alloc(u64, 10);
    defer std.testing.allocator.free(arr);
    inline for (arr, .{ 1, 4, 6, 4, 3, 2, 6, 7, 8, 9 }) |*ptr, val| ptr.* = val;
    const exp: [10]u64 = .{ 1, 2, 3, 4, 4, 6, 6, 7, 8, 9 };

    insertSort(u64, arr.ptr, arr.ptr + 9);
    try std.testing.expect(std.mem.eql(u64, &exp, arr));
}

pub fn main() void {}
