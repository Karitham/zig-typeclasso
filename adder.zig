pub fn Adder(comptime T: type, value: T) fn (T) T {
    return struct {
        fn add(a: T) T {
            return a + value;
        }
    }.add;
}
