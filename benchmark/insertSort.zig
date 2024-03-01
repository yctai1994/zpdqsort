const std = @import("std");
const time = std.time;
const print = std.debug.print;
const testing = std.testing;

const BiasMode = enum(u1) { unbiased, biased };

fn welford(comptime T: type, comptime B: BiasMode, Ex: *T, Vx: *T, xn: T, n: usize) void {
    if (@typeInfo(T) != .Float) @compileError("");

    if (n == 1) {
        Ex.* = xn;
        Vx.* = 0.0;
        return;
    }

    const float_n: T = @floatFromInt(n);
    var M2n: T = Vx.* * switch (B) {
        .unbiased => float_n - 2.0,
        .biased => float_n - 1.0,
    };
    const M1n: T = Ex.* + (xn - Ex.*) / float_n;
    M2n += (xn - Ex.*) * (xn - M1n);
    Ex.* = M1n;
    Vx.* = M2n / switch (B) {
        .unbiased => float_n - 1.0,
        .biased => float_n,
    };

    return;
}

// Sorts [begin, end) using insertion sort in an ascending order.
fn insertSort1(comptime T: type, bptr: [*]T, eptr: [*]T) void {
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

test "insertSort1" {
    const arr: []u64 = try std.testing.allocator.alloc(u64, 10);
    defer std.testing.allocator.free(arr);
    inline for (arr, .{ 1, 4, 6, 4, 3, 2, 6, 7, 8, 9 }) |*ptr, val| ptr.* = val;
    const exp: [10]u64 = .{ 1, 2, 3, 4, 4, 6, 6, 7, 8, 9 };

    insertSort1(u64, arr.ptr, arr.ptr + 9);
    try std.testing.expect(std.mem.eql(u64, &exp, arr));
}

fn insertSort2(comptime T: type, begin: *T, end: *T) void {
    const addr_step: comptime_int = comptime @sizeOf(T);
    if (begin == end) return;
    var cur: *T = @ptrFromInt(@intFromPtr(begin) + addr_step);
    while (cur != end) : (cur = @ptrFromInt(@intFromPtr(cur) + addr_step)) {
        var sift: *T = cur;
        var sift_1: *T = @ptrFromInt(@intFromPtr(cur) - addr_step);
        if (sift.* < sift_1.*) {
            const tmp: T = sift.*;
            sift.* = sift_1.*;
            sift = @ptrFromInt(@intFromPtr(sift) - addr_step);
            sift_1 = @ptrFromInt(@intFromPtr(sift_1) - addr_step);
            while (sift != begin and tmp < sift_1.*) {
                sift.* = sift_1.*;
                sift = @ptrFromInt(@intFromPtr(sift) - addr_step);
                sift_1 = @ptrFromInt(@intFromPtr(sift_1) - addr_step);
            }
            sift.* = tmp;
        }
    }
    return;
}

test "insertSort" {
    const arr: []u64 = try std.testing.allocator.alloc(u64, 10);
    defer std.testing.allocator.free(arr);
    inline for (arr, .{ 1, 4, 6, 4, 3, 2, 6, 7, 8, 9 }) |*ptr, val| ptr.* = val;
    const exp: [10]u64 = .{ 1, 2, 3, 4, 4, 6, 6, 7, 8, 9 };

    insertSort2(u64, &arr[0], &arr[9]);
    try std.testing.expect(std.mem.eql(u64, &exp, arr));
}

pub fn main() !void {
    const itmax: comptime_int = 1000000;

    var biased_mean: f64 = undefined;
    var biased_var: f64 = undefined;
    var timer_read: f64 = undefined;
    var timer = try time.Timer.start();

    const arr: []u64 = try std.heap.page_allocator.alloc(u64, 16);
    defer std.heap.page_allocator.free(arr);
    const exp: [16]u64 = .{ 1, 1, 2, 4, 5, 5, 5, 6, 7, 8, 8, 10, 13, 14, 15, 13 };
    _ = exp;

    // test "benchmark insertSort1"
    // [[insertSort1: Use [*]T]]
    // mean = 58.965181999997874 ns
    // std  = 128.08589422612658 ns
    // eval = 1000000

    for (0..itmax) |n| {
        inline for (arr, .{ 15, 7, 8, 1, 4, 6, 1, 2, 13, 5, 5, 14, 8, 5, 10, 13 }) |*ptr, val| ptr.* = val;
        timer.reset();
        insertSort1(u64, arr.ptr, arr.ptr + 15);
        timer_read = @floatFromInt(timer.read());
        welford(f64, .biased, &biased_mean, &biased_var, timer_read, n + 1);
    }

    print("\n[[insertSort1: Use [*]T]]\n  mean = {d} ns\n  std  = {d} ns\n", .{ biased_mean, @sqrt(biased_var) });
    print("  eval = {any}\n", .{itmax});

    // test "benchmark insertSort2"
    // [[insertSort2: Use *T]]
    // mean = 65.13845099999682 ns
    // std  = 248.79378138997197 ns
    // eval = 1000000
    for (0..itmax) |n| {
        inline for (arr, .{ 15, 7, 8, 1, 4, 6, 1, 2, 13, 5, 5, 14, 8, 5, 10, 13 }) |*ptr, val| ptr.* = val;
        timer.reset();
        insertSort2(u64, &arr[0], &arr[15]);
        timer_read = @floatFromInt(timer.read());
        welford(f64, .biased, &biased_mean, &biased_var, timer_read, n + 1);
    }

    print("\n[[insertSort2: Use *T]]\n  mean = {d} ns\n  std  = {d} ns\n", .{ biased_mean, @sqrt(biased_var) });
    print("  eval = {any}\n", .{itmax});
}
