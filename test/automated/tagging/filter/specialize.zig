const std = @import("std");

const Filter = @import("log").Tagging.Filter;

test "Produces New Filter With Identical Include/Exclude Lists" {
    var source_filter = try Filter.init("some_tag,-other_tag", std.testing.allocator);
    defer source_filter.deinit();

    var filter = source_filter.specialize(&.{});

    filter.state = Filter.State.override;
    try std.testing.expect(source_filter.state != filter.state);

    try std.testing.expect(source_filter.include_list.ptr == filter.include_list.ptr);
    try std.testing.expect(source_filter.exclude_list.ptr == filter.exclude_list.ptr);
}

test "Applies the Given Tags" {
    var source_filter = try Filter.init("some_tag,-other_tag", std.testing.allocator);
    defer source_filter.deinit();

    var filter = source_filter.specialize(&.{ "some_tag", "other_tag" });

    try std.testing.expect(filter.state == Filter.State.exclude);
}
