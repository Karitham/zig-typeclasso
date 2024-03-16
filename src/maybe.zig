const std = @import("std");
const Adder = @import("adder.zig").Adder;

pub fn Maybe(comptime A: type) type {
    return struct {
        const Self = @This();

        value: ?A,

        pub fn just(v: A) Self {
            return Maybe(A){ .value = v };
        }

        pub fn nothing() Self {
            return Maybe(A){ .value = null };
        }

        pub fn fmap(self: Self, B: type, f: fn (A) B) Maybe(B) {
            if (self.value) |v| return Maybe(B).just(f(v));
            return Maybe(B).nothing();
        }

        pub fn apply(self: Self, comptime B: type, other: Maybe(fn (A) B)) Maybe(B) {
            if (self.value) |v| if (other.value) |f| return Maybe(B).just(f(v));
            return Maybe(B).nothing();
        }

        pub fn bind(self: Self, comptime B: type, f: fn (A) Maybe(B)) Maybe(B) {
            if (self.value) |v| return f(v);
            return Maybe(B).nothing();
        }

        pub fn join(self: Maybe(Maybe(A))) Maybe(A) {
            return if (self.value) |v| v else Maybe(A).nothing();
        }
    };
}

fn Adder2(X: type) fn (X, X) X {
    return struct {
        pub fn add(x: X, y: X) X {
            return x + y;
        }
    }.add;
}

fn Double(X: type) fn (X) X {
    return struct {
        pub fn double(x: X) X {
            return x * 2;
        }
    }.double;
}

test "Maybe" {
    const add_one = Adder(i32, 1);
    const M32 = Maybe(i32);
    const MaybeF = Maybe(fn (i32) i32);

    const m1 = M32.just(10);
    const m2 = M32.nothing();

    const added = m1.fmap(i32, add_one);
    const added2 = m2.fmap(i32, add_one);

    try std.testing.expectEqual(added.value.?, 11);
    try std.testing.expectEqual(added2.value, null);

    const value = M32.just(5);
    const double = MaybeF.just(Double(i32));

    const result = value.apply(i32, double);

    try std.testing.expectEqual(result.value.?, 10);
}
