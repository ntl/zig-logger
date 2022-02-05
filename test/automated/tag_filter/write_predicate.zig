const std = @import("std");

const TagFilter = @import("log").Filter.TagFilter;

const some_tag = TagFilter.digest("some_tag");
const other_tag = TagFilter.digest("other_tag");
const another_tag = TagFilter.digest("another_tag");
const override_tag = TagFilter.digest("*");

test "State: Untagged" {
    const tag_filter = TagFilter{
        .state = TagFilter.State.untagged,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(tag_filter.write_predicate(&.{}) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ another_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ override_tag }) == true);
}

test "State: No Match" {
    const tag_filter = TagFilter{
        .state = TagFilter.State.no_match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(tag_filter.write_predicate(&.{}) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ another_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Match" {
    const tag_filter = TagFilter{
        .state = TagFilter.State.match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(tag_filter.write_predicate(&.{}) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ another_tag }) == true);
    try std.testing.expect(tag_filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Exclude" {
    const tag_filter = TagFilter{
        .state = TagFilter.State.exclude,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(tag_filter.write_predicate(&.{}) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(tag_filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Override" {
    const tag_filter = TagFilter{
        .state = TagFilter.State.override,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(tag_filter.write_predicate(&.{ some_tag, other_tag }) == true);
}
