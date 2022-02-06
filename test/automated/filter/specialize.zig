const std = @import("std");

const Filter = @import("log").Filter;

test "Produces New Filter With Identical Include/Exclude Lists And Log Level" {
    var source_filter = try Filter.build(.{
        .logger_level = "info",
        .logger_tags = "some_tag,-other_tag",
    });

    var filter = source_filter.specialize(&.{});

    try std.testing.expect(filter.tag_state == source_filter.tag_state);
    filter.tag_state = .override;
    try std.testing.expect(source_filter.tag_state != filter.tag_state);

    try std.testing.expect(filter.logger_level == source_filter.logger_level);
    filter.logger_level = .debug;
    try std.testing.expect(source_filter.logger_level != filter.logger_level);

    try std.testing.expect(filter.include_tags.ptr == source_filter.include_tags.ptr);
    try std.testing.expect(filter.exclude_tags.ptr == source_filter.exclude_tags.ptr);

    try std.testing.expect(filter.allocator == null);
}

test "Applies the Given Tags" {
    var source_filter = try Filter.build(.{ .logger_tags = "some_tag,-other_tag" });

    var filter = source_filter.specialize(&.{ "some_tag", "other_tag" });

    try std.testing.expect(filter.tag_state == .exclude);
}
