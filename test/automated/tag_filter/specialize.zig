const std = @import("std");

const TagFilter = @import("log").Filter.TagFilter;

test "Produces New Filter With Identical Include/Exclude Lists" {
    var source_filter = try TagFilter.build(.{ .log_tags = "some_tag,-other_tag" });

    var tag_filter = source_filter.specialize(&.{});

    tag_filter.state = TagFilter.State.override;
    try std.testing.expect(source_filter.state != tag_filter.state);

    try std.testing.expect(tag_filter.include_list.ptr == source_filter.include_list.ptr);
    try std.testing.expect(tag_filter.exclude_list.ptr == source_filter.exclude_list.ptr);

    try std.testing.expect(tag_filter.allocator == null);
}

test "Applies the Given Tags" {
    var source_filter = try TagFilter.build(.{ .log_tags = "some_tag,-other_tag" });

    var tag_filter = source_filter.specialize(&.{ "some_tag", "other_tag" });

    try std.testing.expect(tag_filter.state == TagFilter.State.exclude);
}
