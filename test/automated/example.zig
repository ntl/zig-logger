const log = @import("log");

const testing = @import("std").testing;

test "Example test" {
    try testing.expect(log.some_function(11) == 12);
}
