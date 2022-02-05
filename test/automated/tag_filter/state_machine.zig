const std = @import("std");

const TagFilter = @import("log").Filter.TagFilter;

const some_tag = TagFilter.digest("some_tag");

fn test_apply_tag(tag_filter: *TagFilter, tag: []const u8, control_state: TagFilter.State) !void {
    const tag_digest = TagFilter.digest(tag);

    const original_state = tag_filter.state;
    defer tag_filter.state = original_state;

    tag_filter.apply(tag_digest);

    try std.testing.expect(tag_filter.state == control_state);
}

test "Initial State" {
    const tag_filter = TagFilter{};

    try std.testing.expect(tag_filter.state == TagFilter.State.untagged);
}

test "Next State; Untagged State" {
    const untagged_state = TagFilter.State.untagged;

    // LOG_TAGS=""
    var tag_filter = TagFilter{ .state = untagged_state };
    try test_apply_tag(&tag_filter, "_override", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "*", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.no_match);

    // LOG_TAGS="some_tag"
    tag_filter = TagFilter{ .state = untagged_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.match);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);

    // LOG_TAGS="-some_tag"
    tag_filter = TagFilter{ .state = untagged_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    tag_filter = TagFilter{ .state = untagged_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);
}

test "Next State; Match Needed State" {
    const no_match_state = TagFilter.State.no_match;

    // LOG_TAGS=""
    var tag_filter = TagFilter{ .state = no_match_state };
    try test_apply_tag(&tag_filter, "_override", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "*", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.no_match);

    // LOG_TAGS="some_tag"
    tag_filter = TagFilter{ .state = no_match_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.match);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);

    // LOG_TAGS="-some_tag"
    tag_filter = TagFilter{ .state = no_match_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    tag_filter = TagFilter{ .state = no_match_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.no_match);
}

test "Next State; Matched State" {
    const match_state = TagFilter.State.match;

    // LOG_TAGS=""
    var tag_filter = TagFilter{ .state = match_state };
    try test_apply_tag(&tag_filter, "_override", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "*", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.match);

    // LOG_TAGS="some_tag"
    tag_filter = TagFilter{ .state = match_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.match);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.match);

    // LOG_TAGS="-some_tag"
    tag_filter = TagFilter{ .state = match_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.match);

    // LOG_TAGS="-some_tag,some_tag"
    tag_filter = TagFilter{ .state = match_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.match);
}

test "Next State; Excluded State" {
    const excluded_state = TagFilter.State.exclude;

    // LOG_TAGS=""
    var tag_filter = TagFilter{ .state = excluded_state };
    try test_apply_tag(&tag_filter, "_override", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "*", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);

    // LOG_TAGS="some_tag"
    tag_filter = TagFilter{ .state = excluded_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.exclude);

    // LOG_TAGS="-some_tag"
    tag_filter = TagFilter{ .state = excluded_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.exclude);

    // LOG_TAGS="-some_tag,some_tag"
    tag_filter = TagFilter{ .state = excluded_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.exclude);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.exclude);
}

test "Next State; Print State" {
    const print_state = TagFilter.State.override;

    // LOG_TAGS=""
    var tag_filter = TagFilter{ .state = print_state };
    try test_apply_tag(&tag_filter, "_override", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "*", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.override);

    // LOG_TAGS="some_tag"
    tag_filter = TagFilter{ .state = print_state, .include_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.override);

    // LOG_TAGS="-some_tag"
    tag_filter = TagFilter{ .state = print_state, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.override);

    // LOG_TAGS="-some_tag,some_tag"
    tag_filter = TagFilter{ .state = print_state, .include_list = &.{ some_tag }, .exclude_list = &.{ some_tag } };
    try test_apply_tag(&tag_filter, "some_tag", TagFilter.State.override);
    try test_apply_tag(&tag_filter, "other_tag", TagFilter.State.override);
}
