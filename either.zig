const std = @import("std");
const Adder = @import("adder.zig").Adder;

fn AddOne(comptime T: type) fn (T) T {
    return Adder(T, 1);
}

fn Either(comptime L: type, comptime R: type) type {
    return union(enum) {
        left: L,
        right: R,

        fn fmap(self: @This(), comptime U: type, comptime f: fn (U) U) @This() {
            return switch (self) {
                .left => |l| if (U == L) Either(L, R){ .left = f(l) } else self,
                .right => |r| if (U == R) Either(L, R){ .right = f(r) } else self,
            };
        }
    };
}

fn either(comptime L: type, comptime R: type, v: union(enum) { left: L, right: R }) Either(L, R) {
    return switch (v) {
        .left => |l| Either(L, R){ .left = l },
        .right => |r| Either(L, R){ .right = r },
    };
}

test "Either" {
    const eq = std.testing.expectEqual;

    const added1 = either(i32, i32, .{ .left = 10 }).fmap(i32, AddOne(i32));
    try eq(added1.left, 11);

    const added2 = either(i32, i32, .{ .right = 10 }).fmap(i32, AddOne(i32));
    try eq(added2.right, 11);

    const added3 = either(i32, f32, .{ .right = 10 }).fmap(f32, AddOne(f32));
    try eq(added3.right, 11);
}

fn EitherImpl(
    comptime L: type,
    comptime R: type,
    comptime liftL: fn (L) L,
    comptime liftR: fn (R) R,
) type {
    return union(enum) {
        left: L,
        right: R,

        const Self = @This();
        fn fmap(self: Self) Self {
            return switch (self) {
                .left => |l| Self{ .left = liftL(l) },
                .right => |r| Self{ .right = liftR(r) },
            };
        }
    };
}

fn implEither(
    comptime L: type,
    comptime R: type,
    comptime liftL: fn (L) L,
    comptime liftR: fn (R) R,
    v: union(enum) { left: L, right: R },
) EitherImpl(L, R, liftL, liftR) {
    return switch (v) {
        .left => |l| EitherImpl(L, R, liftL, liftR){ .left = l },
        .right => |r| EitherImpl(L, R, liftL, liftR){ .right = r },
    };
}

test "LoadedEither" {
    const eq = std.testing.expectEqual;
    const A = i32;
    const B = f32;

    const lifted = implEither(
        A,
        B,
        Adder(A, 2),
        Adder(B, 10),
        .{ .left = 10 },
    ).fmap();

    try eq(lifted.left, 12);
}
