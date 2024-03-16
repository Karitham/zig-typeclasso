const std = @import("std");
const Adder = @import("adder.zig").Adder;

fn Either(comptime L: type, comptime R: type) type {
    return union(enum) {
        const Self = @This();

        left: L,
        right: R,

        fn fmap(self: Self, comptime liftl: fn (L) L, liftr: fn (R) R) Self {
            return switch (self) {
                .left => |l| Either(L, R){ .left = liftl(l) },
                .right => |r| Either(L, R){ .right = liftr(r) },
            };
        }

        fn left(self: L) Self {
            return Self{ .left = self };
        }

        fn right(self: R) Self {
            return Self{ .right = self };
        }
    };
}

test "Either" {
    const eq = std.testing.expectEqual;
    const EitherI32I32 = Either(i32, i32);
    const add_one = Adder(i32, 1);

    const added1 = EitherI32I32.left(10).fmap(add_one, add_one);
    try eq(added1.left, 11);

    const added2 = EitherI32I32.right(10).fmap(add_one, add_one);
    try eq(added2.right, 11);

    const added3 = EitherI32I32.right(10).fmap(add_one, add_one);
    try eq(added3.right, 11);
}

fn EitherImpl(
    comptime L: type,
    comptime R: type,
) type {
    const EitherValueL = struct {
        value: L,
        lift: fn (L) L,
    };

    const EitherValueR = struct {
        value: R,
        lift: fn (R) R,
    };

    return union(enum) {
        left: EitherValueL,
        right: EitherValueR,

        const Self = @This();
        fn fmap(self: Self) Self {
            return switch (self) {
                .left => |value| {
                    const lifted = value.lift(value.value);
                    return Self{
                        .left = EitherValueL{
                            .value = lifted,
                            .lift = value.lift,
                        },
                    };
                },
                .right => |value| {
                    const lifted = value.lift(value.value);
                    return Self{
                        .right = EitherValueR{
                            .value = lifted,
                            .lift = value.lift,
                        },
                    };
                },
            };
        }

        fn left(liftL: fn (L) L, value: L) Self {
            return Self{
                .left = EitherValueL{
                    .value = value,
                    .lift = liftL,
                },
            };
        }

        fn right(liftR: fn (R) R, value: R) Self {
            return Self{
                .right = EitherValueR{
                    .value = value,
                    .lift = liftR,
                },
            };
        }
    };
}

test "LoadedEither" {
    const eq = std.testing.expectEqual;
    const A = i32;
    const B = f32;

    const lifted = EitherImpl(A, B).left(Adder(A, 10), 2).fmap();

    try eq(lifted.left.value, 12);
}
