const std = @import("std");

const Log = @import("log");
const Filter = Log.Tagging.Filter;
const Digest = Log.Tagging.Digest;

test "Initial State" {
    const filter = Filter{};

    try std.testing.expect(filter.state == Filter.State.untagged);
}

test "Add Tag" {
    var filter = Filter{ .state = Filter.State.untagged, .include_list = Digest.tags(.{"some_tag"}) };

    filter.addTag(Digest.tag("some_tag"));

    try std.testing.expect(filter.state == Filter.State.matched);
}

test "Build" {
    var filter = try Filter.build();

    try std.testing.expect(@TypeOf(filter) == Filter);
}

test "State Machine" {
    _ = @import("./filter/state_machine.zig");
}

test "Build" {
    _ = @import("./filter/init.zig");
}
