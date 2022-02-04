const std = @import("std");

const Log = @import("log");
const Filter = Log.Tagging.Filter;
const Digest = Log.Tagging.Digest;

fn testNextState(filter: Filter, tag: []const u8, control_state: Filter.State) !void {
    const tag_digest = Digest.tag(tag);

    const nextState = filter.nextState(tag_digest);

    try std.testing.expect(nextState == control_state);
}

test "Next State; Untagged State" {
    const untagged_state = Filter.State.untagged;

    // LOG_TAGS=""
    var filter = Filter{ .state = untagged_state };
    try testNextState(filter, "_override", Filter.State.print);
    try testNextState(filter, "*", Filter.State.print);
    try testNextState(filter, "some_tag", Filter.State.match_needed);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = untagged_state, .include_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.matched);
    try testNextState(filter, "other_tag", Filter.State.match_needed);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = untagged_state, .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.match_needed);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = untagged_state, .include_list = Digest.tags(.{"some_tag"}), .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.match_needed);
}

test "Next State; Match Needed State" {
    const match_needed_state = Filter.State.match_needed;

    // LOG_TAGS=""
    var filter = Filter{ .state = match_needed_state };
    try testNextState(filter, "_override", Filter.State.print);
    try testNextState(filter, "*", Filter.State.print);
    try testNextState(filter, "some_tag", Filter.State.match_needed);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = match_needed_state, .include_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.matched);
    try testNextState(filter, "other_tag", Filter.State.match_needed);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = match_needed_state, .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.match_needed);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = match_needed_state, .include_list = Digest.tags(.{"some_tag"}), .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.match_needed);
}

test "Next State; Matched State" {
    const matched_state = Filter.State.matched;

    // LOG_TAGS=""
    var filter = Filter{ .state = matched_state };
    try testNextState(filter, "_override", Filter.State.print);
    try testNextState(filter, "*", Filter.State.print);
    try testNextState(filter, "some_tag", Filter.State.matched);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = matched_state, .include_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.matched);
    try testNextState(filter, "other_tag", Filter.State.matched);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = matched_state, .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.matched);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = matched_state, .include_list = Digest.tags(.{"some_tag"}), .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.matched);
}

test "Next State; Excluded State" {
    const excluded_state = Filter.State.excluded;

    // LOG_TAGS=""
    var filter = Filter{ .state = excluded_state };
    try testNextState(filter, "_override", Filter.State.print);
    try testNextState(filter, "*", Filter.State.print);
    try testNextState(filter, "some_tag", Filter.State.excluded);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = excluded_state, .include_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.excluded);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = excluded_state, .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.excluded);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = excluded_state, .include_list = Digest.tags(.{"some_tag"}), .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.excluded);
    try testNextState(filter, "other_tag", Filter.State.excluded);
}

test "Next State; Print State" {
    const print_state = Filter.State.print;

    // LOG_TAGS=""
    var filter = Filter{ .state = print_state };
    try testNextState(filter, "_override", Filter.State.print);
    try testNextState(filter, "*", Filter.State.print);
    try testNextState(filter, "some_tag", Filter.State.print);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = print_state, .include_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.print);
    try testNextState(filter, "other_tag", Filter.State.print);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = print_state, .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.print);
    try testNextState(filter, "other_tag", Filter.State.print);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = print_state, .include_list = Digest.tags(.{"some_tag"}), .exclude_list = Digest.tags(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.print);
    try testNextState(filter, "other_tag", Filter.State.print);
}
