const std = @import("std");

const Log = @import("log");
const Filter = Log.Tagging.Filter;

fn testNextState(filter: Filter, tag: []const u8, control_state: Filter.State) !void {
    const tag_digest = Filter.tag_digest(tag);

    const nextState = filter.nextState(tag_digest);

    try std.testing.expect(nextState == control_state);
}

pub fn tag_digests(comptime tags: anytype) []const u64 {
    comptime {
        var digests: [tags.len]u64 = .{0} ** tags.len;

        for (tags) |tag, index| {
            const digest = Filter.tag_digest(tag);
            digests[index] = digest;
        }

        return &digests;
    }
}

test "Next State; Untagged State" {
    const untagged_state = Filter.State.untagged;

    // LOG_TAGS=""
    var filter = Filter{ .state = untagged_state };
    try testNextState(filter, "_override", Filter.State.override);
    try testNextState(filter, "*", Filter.State.override);
    try testNextState(filter, "some_tag", Filter.State.no_match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = untagged_state, .include_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.match);
    try testNextState(filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = untagged_state, .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = untagged_state, .include_list = tag_digests(.{"some_tag"}), .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.no_match);
}

test "Next State; Match Needed State" {
    const no_match_state = Filter.State.no_match;

    // LOG_TAGS=""
    var filter = Filter{ .state = no_match_state };
    try testNextState(filter, "_override", Filter.State.override);
    try testNextState(filter, "*", Filter.State.override);
    try testNextState(filter, "some_tag", Filter.State.no_match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = no_match_state, .include_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.match);
    try testNextState(filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = no_match_state, .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.no_match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = no_match_state, .include_list = tag_digests(.{"some_tag"}), .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.no_match);
}

test "Next State; Matched State" {
    const match_state = Filter.State.match;

    // LOG_TAGS=""
    var filter = Filter{ .state = match_state };
    try testNextState(filter, "_override", Filter.State.override);
    try testNextState(filter, "*", Filter.State.override);
    try testNextState(filter, "some_tag", Filter.State.match);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = match_state, .include_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.match);
    try testNextState(filter, "other_tag", Filter.State.match);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = match_state, .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.match);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = match_state, .include_list = tag_digests(.{"some_tag"}), .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.match);
}

test "Next State; Excluded State" {
    const excluded_state = Filter.State.exclude;

    // LOG_TAGS=""
    var filter = Filter{ .state = excluded_state };
    try testNextState(filter, "_override", Filter.State.override);
    try testNextState(filter, "*", Filter.State.override);
    try testNextState(filter, "some_tag", Filter.State.exclude);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = excluded_state, .include_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.exclude);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = excluded_state, .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.exclude);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = excluded_state, .include_list = tag_digests(.{"some_tag"}), .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.exclude);
    try testNextState(filter, "other_tag", Filter.State.exclude);
}

test "Next State; Print State" {
    const print_state = Filter.State.override;

    // LOG_TAGS=""
    var filter = Filter{ .state = print_state };
    try testNextState(filter, "_override", Filter.State.override);
    try testNextState(filter, "*", Filter.State.override);
    try testNextState(filter, "some_tag", Filter.State.override);

    // LOG_TAGS="some_tag"
    filter = Filter{ .state = print_state, .include_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.override);
    try testNextState(filter, "other_tag", Filter.State.override);

    // LOG_TAGS="-some_tag"
    filter = Filter{ .state = print_state, .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.override);
    try testNextState(filter, "other_tag", Filter.State.override);

    // LOG_TAGS="-some_tag,some_tag"
    filter = Filter{ .state = print_state, .include_list = tag_digests(.{"some_tag"}), .exclude_list = tag_digests(.{"some_tag"}) };
    try testNextState(filter, "some_tag", Filter.State.override);
    try testNextState(filter, "other_tag", Filter.State.override);
}
