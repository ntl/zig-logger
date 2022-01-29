const TEMPLATE_CONST = @import("TEMPLATE_LIBRARY");

const testing = @import("std").testing;

test "Example test" {
    try testing.expect(TEMPLATE_CONST.some_function(11) == 12);
}
