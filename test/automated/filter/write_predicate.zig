const std = @import("std");

const Filter = @import("log").Filter;

const some_tag = Filter.digest("some_tag");
const other_tag = Filter.digest("other_tag");
const another_tag = Filter.digest("another_tag");
const override_tag = Filter.digest("_override");

test "Message Level" {
    const filter = Filter{
        .logger_level = .info,
        .state = .untagged,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.fatal, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.err, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.warn, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.debug, &.{}) == false);
    try std.testing.expect(filter.write_predicate(.trace, &.{}) == false);

    try std.testing.expect(filter.write_predicate(.info, &.{ other_tag }) == false);
    try std.testing.expect(filter.write_predicate(.debug, &.{ some_tag }) == false);
    try std.testing.expect(filter.write_predicate(.debug, &.{ override_tag }) == false);
}

test "State: Untagged" {
    const filter = Filter{
        .state = .untagged,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.info, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ another_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ override_tag }) == true);
}

test "State: No Match" {
    const filter = Filter{
        .state = .no_match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.info, &.{}) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ another_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ override_tag }) == true);
}

test "State: Match" {
    const filter = Filter{
        .state = .match,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.info, &.{}) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag }) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ another_tag }) == true);
    try std.testing.expect(filter.write_predicate(.info, &.{ override_tag }) == true);
}

test "State: Exclude" {
    const filter = Filter{
        .state = .exclude,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.info, &.{}) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag, other_tag }) == false);
    try std.testing.expect(filter.write_predicate(.info, &.{ override_tag }) == true);
}

test "State: Override" {
    const filter = Filter{
        .state = .override,
        .include_list = &.{ some_tag },
        .exclude_list = &.{ other_tag },
    };

    try std.testing.expect(filter.write_predicate(.info, &.{ some_tag, other_tag }) == true);
}
