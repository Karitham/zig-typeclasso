const std = @import("std");
const Adder = @import("adder.zig").Adder;
const Maybe = @import("maybe.zig").Maybe;

pub fn ZipList(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        context: []const T,

        pub fn init(alloc: std.mem.Allocator, ctx: []const T) Self {
            return Self{ .allocator = alloc, .context = ctx };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.context);
            self.context = undefined;
            self.allocator = undefined;
        }

        pub fn @"<*>"(self: Self, fmap: fn (T) T) !Self {
            var new_ctx = try self.allocator.alloc(T, self.context.len);
            for (self.context, 0..self.context.len) |item, i| {
                new_ctx[i] = fmap(item);
            }

            return Self{
                .allocator = self.allocator,
                .context = new_ctx,
            };
        }
    };
}

fn Tuple(comptime T: type) type {
    return struct {
        const Self = @This();

        left: T,
        right: T,

        pub fn fmap(self: Self, f: fn (T) T) Self {
            return Self{
                .left = f(self.left),
                .right = f(self.right),
            };
        }
    };
}

fn scaleN(Container: type, Inner: type, n: Inner) fn (Container) Container {
    if (!@hasDecl(Container, "fmap")) {
        @compileError("T must impl fmap: (fn (T) T)");
    }

    return struct {
        fn scale(t: Container) Container {
            return t.fmap(struct {
                fn scale(j: Inner) Inner {
                    return j * n;
                }
            }.scale);
        }
    }.scale;
}

test ZipList {
    const testing = std.testing;
    const alloc = testing.allocator;

    {
        const zp = ZipList(u32).init(alloc, &.{});
        var zp2 = try zp.@"<*>"(Adder(u32, 2));
        defer zp2.deinit();
        try testing.expectEqual(zp2.context.len, 0);
    }

    {
        const zp = ZipList(u32).init(alloc, &.{ 1, 2, 3 });
        var zp2 = try zp.@"<*>"(Adder(u32, 2));
        defer zp2.deinit();

        try testing.expectEqual(zp2.context.len, 3);
        try testing.expectEqual(zp2.context[0], 3);
        try testing.expectEqual(zp2.context[1], 4);
        try testing.expectEqual(zp2.context[2], 5);
    }

    {
        const MaybeU32 = Maybe(u32);
        const zp = ZipList(MaybeU32).init(alloc, &.{
            MaybeU32.just(1),
            MaybeU32.nothing(),
            MaybeU32.just(3),
            MaybeU32.just(4),
        });
        var zp2 = try zp.@"<*>"(scaleN(MaybeU32, u32, 2));
        defer zp2.deinit();

        try testing.expectEqual(zp2.context.len, 4);
        try testing.expectEqual(zp2.context[0].just, 2);
        try testing.expectEqual(zp2.context[1].just, null);
        try testing.expectEqual(zp2.context[2].just, 6);
        try testing.expectEqual(zp2.context[3].just, 8);
    }

    {
        const T2U32 = Tuple(u32);
        const zp = ZipList(T2U32).init(alloc, &.{
            Tuple(u32){ .left = 2, .right = 3 },
            Tuple(u32){ .left = 3, .right = 4 },
        });
        var zp2 = try zp.@"<*>"(scaleN(T2U32, u32, 2));
        defer zp2.deinit();

        try testing.expectEqual(zp2.context.len, 2);
    }
}
