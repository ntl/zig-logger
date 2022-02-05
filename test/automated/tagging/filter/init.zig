const std = @import("std");

const Filter = @import("log").Tagging.Filter;

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

    try std.testing.expect(filter.state == Filter.State.no_match);

    try std.testing.expect(filter.include_list.len == 1);
    try std.testing.expect(filter.include_list[0] == Filter.tag_digest("some_tag"));
}

test "LOG_TAGS='some_tag,other_tag'" {
    var filter = try Filter.init("some_tag,other_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.no_match);

    try std.testing.expect(filter.include_list.len == 2);
    try std.testing.expect(filter.include_list[0] == Filter.tag_digest("some_tag"));
    try std.testing.expect(filter.include_list[1] == Filter.tag_digest("other_tag"));
}

test "LOG_TAGS='-some_tag'" {
    var filter = try Filter.init("-some_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.no_match);

    try std.testing.expect(filter.exclude_list.len == 1);
    try std.testing.expect(filter.exclude_list[0] == Filter.tag_digest("some_tag"));
}

test "LOG_TAGS='some_tag,-other_tag'" {
    var filter = try Filter.init("some_tag,-other_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.include_list.len == 1);
    try std.testing.expect(filter.include_list[0] == Filter.tag_digest("some_tag"));

    try std.testing.expect(filter.exclude_list.len == 1);
    try std.testing.expect(filter.exclude_list[0] == Filter.tag_digest("other_tag"));

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

    try std.testing.expect(filter.state == Filter.State.override);
    try std.testing.expect(filter.include_list.len == 0);
    try std.testing.expect(filter.exclude_list.len == 0);
}

test "LOG_TAGS='some_tag,-other_tag,_all,yet_another_tag'" {
    var filter = try Filter.init("some_tag,-other_tag,_all,yet_another_tag", std.testing.allocator);
    defer filter.deinit();

    try std.testing.expect(filter.state == Filter.State.override);
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
    try std.testing.expect(filter.include_list[0] == Filter.tag_digest("some_tag"));
    try std.testing.expect(filter.include_list[1] == Filter.tag_digest("other_tag"));
    try std.testing.expect(filter.exclude_list.len == 0);
}
