const std = @import("std");
const Adder = @import("adder.zig").Adder;

fn AddOne(comptime T: type) fn (T) T {
    return Adder(T, 1);
}

// Generic law
fn Functor(comptime T: type) type {
    return struct {
        pub fn fmap(comptime U: type, f: fn (T) U, self: T) U {
            return f(self);
        }
    };
}

fn Maybe(comptime T: type) type {
    return struct {
        value: ?T,

        fn fmap(self: @This(), comptime U: type, f: fn (T) U) Maybe(U) {
            if (self.value) |v| {
                return Maybe(U){ .value = f(v) };
            } else {
                return Maybe(U){ .value = null };
            }
        }
    };
}

fn maybe(comptime T: type, v: ?T) Maybe(T) {
    return Maybe(T){ .value = v };
}

test "Maybe" {
    const m1 = maybe(i32, 10);
    const m2 = maybe(i32, null);

    const added = m1.fmap(i32, AddOne(i32));
    const added2 = m2.fmap(i32, AddOne(i32));

    try std.testing.expectEqual(@as(i32, 11), added.value.?);
    try std.testing.expectEqual(@as(?i32, null), added2.value);
}
