const std = @import("std");

const Filter = @import("log").Filter;

test "Produces New Filter With Identical Include/Exclude Lists" {
    var source_filter = try Filter.build(.{ .log_tags = "some_tag,-other_tag" });

    var filter = source_filter.specialize(&.{});

    filter.state = Filter.State.override;
    try std.testing.expect(source_filter.state != filter.state);

    try std.testing.expect(filter.include_list.ptr == source_filter.include_list.ptr);
    try std.testing.expect(filter.exclude_list.ptr == source_filter.exclude_list.ptr);

    try std.testing.expect(filter.allocator == null);
}

test "Applies the Given Tags" {
    var source_filter = try Filter.build(.{ .log_tags = "some_tag,-other_tag" });

    var filter = source_filter.specialize(&.{ "some_tag", "other_tag" });

    try std.testing.expect(filter.state == Filter.State.exclude);
}
