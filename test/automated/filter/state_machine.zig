const std = @import("std");

const Filter = @import("log").Filter;

const some_tag = Filter.digest("some_tag");

fn test_apply_tag(filter: *Filter, tag: []const u8, control_state: Filter.State) !void {
    const tag_digest = Filter.digest(tag);

    const original_state = filter.state;
    defer filter.state = original_state;

    filter.apply(tag_digest);

    try std.testing.expect(filter.state == control_state);
}

test "Initial State" {
    const filter = Filter{};

    try std.testing.expect(filter.state == Filter.State.untagged);
}

test "Next State; Untagged State" {
    const untagged_state = Filter.State.untagged;

    // LOG_TAGS=""
    var filter = Filter{ .state = untagged_state };
    try test_apply_tag(&filter, "_override", Filter.State.override);
    try test_apply_tag(&filter, "*", Filter.State.override);
    try test_apply_tag(&filter, "some_tag", Filter.State.no_match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = untagged_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.match);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = untagged_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = untagged_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);
}

test "Next State; No Match State" {
    const no_match_state = Filter.State.no_match;

    // LOG_TAGS=""
    var filter = Filter{ .state = no_match_state };
    try test_apply_tag(&filter, "_override", Filter.State.override);
    try test_apply_tag(&filter, "*", Filter.State.override);
    try test_apply_tag(&filter, "some_tag", Filter.State.no_match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = no_match_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.match);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = no_match_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = no_match_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.no_match);
}

test "Next State; Match State" {
    const match_state = Filter.State.match;

    // LOG_TAGS=""
    var filter = Filter{ .state = match_state };
    try test_apply_tag(&filter, "_override", Filter.State.override);
    try test_apply_tag(&filter, "*", Filter.State.override);
    try test_apply_tag(&filter, "some_tag", Filter.State.match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = match_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.match);
    try test_apply_tag(&filter, "other_tag", Filter.State.match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = match_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = match_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.match);
}

test "Next State; Exclude State" {
    const excluded_state = Filter.State.exclude;

    // LOG_TAGS=""
    var filter = Filter{ .state = excluded_state };
    try test_apply_tag(&filter, "_override", Filter.State.override);
    try test_apply_tag(&filter, "*", Filter.State.override);
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = excluded_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.exclude);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = excluded_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.exclude);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = excluded_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.exclude);
    try test_apply_tag(&filter, "other_tag", Filter.State.exclude);
}

test "Next State; Override State" {
    const print_state = Filter.State.override;

    // LOG_TAGS=""
    var filter = Filter{ .state = print_state };
    try test_apply_tag(&filter, "_override", Filter.State.override);
    try test_apply_tag(&filter, "*", Filter.State.override);
    try test_apply_tag(&filter, "some_tag", Filter.State.override);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = print_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.override);
    try test_apply_tag(&filter, "other_tag", Filter.State.override);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = print_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.override);
    try test_apply_tag(&filter, "other_tag", Filter.State.override);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = print_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&filter, "some_tag", Filter.State.override);
    try test_apply_tag(&filter, "other_tag", Filter.State.override);
}
