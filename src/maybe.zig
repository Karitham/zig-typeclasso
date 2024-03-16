const std = @import("std");
const Adder = @import("adder.zig").Adder;

// Generic law
fn Functor(comptime T: type) type {
    return struct {
        pub fn fmap(self: T, comptime U: type, f: fn (T) U) U {
            return f(self);
        }
    };
}

pub fn Maybe(comptime T: type) type {
    return struct {
        just: ?T,

        pub fn fmap(self: @This(), f: fn (T) T) Maybe(T) {
            if (self.just) |v| {
                return Maybe(T){ .just = f(v) };
            } else {
                return Maybe(T){ .just = null };
            }
        }

        pub fn just(v: T) @This() {
            return Maybe(T){ .just = v };
        }

        pub fn nothing() @This() {
            return Maybe(T){ .just = null };
        }
    };
}

test "Maybe" {
    const add_one = Adder(i32, 1);

    const m1 = Maybe(i32).just(10);
    const m2 = Maybe(i32).nothing();

    const added = m1.fmap(add_one);
    const added2 = m2.fmap(add_one);

    try std.testing.expectEqual(@as(i32, 11), added.just.?);
    try std.testing.expectEqual(@as(?i32, null), added2.just);
}
