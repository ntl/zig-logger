const std = @import("std");

const Filter = @import("log").Filter;

test "No LOG_LEVEL" {
    var filter = try Filter.build(.{
        .log_level = null,
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .info);
}

test "LOG_LEVEL='fatal'" {
    var filter = try Filter.build(.{
        .log_level = "fatal",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .fatal);
}

test "LOG_LEVEL='error'" {
    var filter = try Filter.build(.{
        .log_level = "error",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .err);
}

test "LOG_LEVEL='warn'" {
    var filter = try Filter.build(.{
        .log_level = "warn",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .warn);
}

test "LOG_LEVEL='info'" {
    var filter = try Filter.build(.{
        .log_level = "info",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .info);
}

test "LOG_LEVEL='debug'" {
    var filter = try Filter.build(.{
        .log_level = "debug",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .debug);
}

test "LOG_LEVEL='trace'" {
    var filter = try Filter.build(.{
        .log_level = "trace",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.logger_level == .trace);
}

test "LOG_LEVEL='not-a-level'" {
    var result = Filter.build(.{
        .log_level = "not-a-level",
        .allocator = std.testing.allocator,
    });

    try std.testing.expectError(Filter.UnknownLogLevelError, result);
}

test "LOG_LEVEL='err'" {
    var result = Filter.build(.{
        .log_level = "err",
        .allocator = std.testing.allocator,
    });

    try std.testing.expectError(Filter.UnknownLogLevelError, result);
}
