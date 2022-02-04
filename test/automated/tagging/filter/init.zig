const std = @import("std");

const Filter = @import("log").Tagging.Filter;
const Digest = @import("log").Tagging.Digest;

test "LOG_TAGS=''" {
    var filter = try Filter.init("", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.untagged);
    try std.testing.expect(filter.exclude_list.len == 0);
    try std.testing.expect(filter.include_list.len == 0);
}

test "LOG_TAGS='some_tag'" {
    var filter = try Filter.init("some_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.match_needed);

    try std.testing.expect(filter.include_list.len == 1);
    try std.testing.expect(filter.include_list[0] == Digest.tag("some_tag"));
}

test "LOG_TAGS='some_tag,other_tag'" {
    var filter = try Filter.init("some_tag,other_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.match_needed);

    try std.testing.expect(filter.include_list.len == 2);
    try std.testing.expect(filter.include_list[0] == Digest.tag("some_tag"));
    try std.testing.expect(filter.include_list[1] == Digest.tag("other_tag"));
}

test "LOG_TAGS='-some_tag'" {
    var filter = try Filter.init("-some_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.match_needed);

    try std.testing.expect(filter.exclude_list.len == 1);
    try std.testing.expect(filter.exclude_list[0] == Digest.tag("some_tag"));
}

test "LOG_TAGS='some_tag,-other_tag'" {
    var filter = try Filter.init("some_tag,-other_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.include_list.len == 1);
    try std.testing.expect(filter.include_list[0] == Digest.tag("some_tag"));

    try std.testing.expect(filter.exclude_list.len == 1);
    try std.testing.expect(filter.exclude_list[0] == Digest.tag("other_tag"));

}

test "LOG_TAGS='_untagged'" {
    var filter = try Filter.init("_untagged", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.untagged);
    try std.testing.expect(filter.include_list.len == 0);
    try std.testing.expect(filter.exclude_list.len == 0);
}

test "LOG_TAGS='some_tag,_untagged,-other_tag'" {
    var filter = try Filter.init("some_tag,_untagged,-other_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.untagged);
    try std.testing.expect(filter.include_list.len == 1);
    try std.testing.expect(filter.exclude_list.len == 1);
}

test "LOG_TAGS='_all'" {
    var filter = try Filter.init("_all", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.print);
    try std.testing.expect(filter.include_list.len == 0);
    try std.testing.expect(filter.exclude_list.len == 0);
}

test "LOG_TAGS='some_tag,-other_tag,_all,yet_another_tag'" {
    var filter = try Filter.init("some_tag,-other_tag,_all,yet_another_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.print);
    try std.testing.expect(filter.include_list.len == 0);
    try std.testing.expect(filter.exclude_list.len == 0);
}

test "LOG_TAGS='_unknown_special_tag'" {
    var filter = try Filter.init("_unknown_special_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.include_list.len == 0);
}

test "LOG_TAGS='-'" {
    var filter = try Filter.init("-", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.include_list.len == 0);
    try std.testing.expect(filter.exclude_list.len == 0);
}

test "Tokenization" {
    var filter = try Filter.init(",  ,,,  ,, ,some_tag,, ,, ,, other_tag  ,,", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.include_list.len == 2);
    try std.testing.expect(filter.include_list[0] == Digest.tag("some_tag"));
    try std.testing.expect(filter.include_list[1] == Digest.tag("other_tag"));
    try std.testing.expect(filter.exclude_list.len == 0);
}
