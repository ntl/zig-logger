const std = @import("std");

const Log = @import("log");
const Filter = Log.Tagging.Filter;

test "Initial State" {
    const filter = Filter{};

    try std.testing.expect(filter.state == Filter.State.untagged);
}

test "Build" {
    var filter = try Filter.build();

    try std.testing.expect(@TypeOf(filter) == Filter);
}

test "Digest" {
    const digest_1: u64 = Filter.tag_digest("some_tag");
    const digest_2: u64 = Filter.tag_digest("some_tag");
    const digest_3: u64 = Filter.tag_digest("other_tag");

    try std.testing.expect(digest_1 == digest_2);
    try std.testing.expect(digest_1 != digest_3);
}

test "State Machine" {
    _ = @import("./filter/state_machine.zig");
}

test "Build" {
    _ = @import("./filter/init.zig");
}

test "Specialize" {
    _ = @import("./filter/specialize.zig");
}
