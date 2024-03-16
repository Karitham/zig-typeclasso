test {
    const std = @import("std");
    std.testing.refAllDeclsRecursive(@import("adder.zig"));
    std.testing.refAllDeclsRecursive(@import("maybe.zig"));
    std.testing.refAllDeclsRecursive(@import("either.zig"));
    std.testing.refAllDeclsRecursive(@import("ziplist.zig"));
}
