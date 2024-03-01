const std = @import("std");

// Sorts [begin, end) using insertion sort in an ascending order.
fn insertSort(comptime T: type, bptr: [*]T, eptr: [*]T) void {
    if (bptr == eptr) return;
    var cptr: [*]T = bptr + 1; // cptr: current ptr
    while (cptr != eptr) : (cptr += 1) {
        var rptr: [*]T = cptr; // rptr: right ptr
        var lptr: [*]T = cptr - 1; // lptr: left ptr
        if (rptr[0] < lptr[0]) {
            const tmp: T = rptr[0];
            rptr[0] = lptr[0];
            rptr -= 1;
            lptr -= 1;
            while (rptr != bptr and tmp < lptr[0]) {
                rptr[0] = lptr[0];
                rptr -= 1;
                lptr -= 1;
            }
            rptr[0] = tmp;
        }
    }
    return;
}

test "insertSort" {
    const arr: []u64 = try std.testing.allocator.alloc(u64, 16);
    defer std.testing.allocator.free(arr);
    inline for (arr, .{ 15, 7, 8, 1, 4, 6, 13, 2, 13, 5, 5, 14, 8, 5, 10, 1 }) |*ptr, val| ptr.* = val;
    const exp: [16]u64 = .{ 1, 2, 4, 5, 5, 5, 6, 7, 8, 8, 10, 13, 13, 14, 15, 1 };

    insertSort(u64, arr.ptr, arr.ptr + 15);
    try std.testing.expect(std.mem.eql(u64, &exp, arr));
}

pub fn main() void {}
