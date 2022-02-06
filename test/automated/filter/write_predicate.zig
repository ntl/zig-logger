const std = @import("std");

const Filter = @import("log").Filter;

const some_tag = Filter.digest("some_tag");
const other_tag = Filter.digest("other_tag");
const another_tag = Filter.digest("another_tag");
const override_tag = Filter.digest("_override");

test "State: Untagged" {
    const filter = Filter{
        .state = Filter.State.untagged,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(&.{}) == true);
    try std.testing.expect(filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ another_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ override_tag }) == true);
}

test "State: No Match" {
    const filter = Filter{
        .state = Filter.State.no_match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(&.{}) == false);
    try std.testing.expect(filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ another_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Match" {
    const filter = Filter{
        .state = Filter.State.match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(&.{}) == true);
    try std.testing.expect(filter.write_predicate(&.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ another_tag }) == true);
    try std.testing.expect(filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Exclude" {
    const filter = Filter{
        .state = Filter.State.exclude,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(&.{}) == false);
    try std.testing.expect(filter.write_predicate(&.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(&.{ override_tag }) == true);
}

test "State: Override" {
    const filter = Filter{
        .state = Filter.State.override,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(&.{ some_tag, other_tag }) == true);
}
