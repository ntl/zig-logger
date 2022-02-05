const std = @import("std");

const TagFilter = @import("log").Filter.TagFilter;

test "No Arguments" {
    var tag_filter = try TagFilter.build(.{});

    try std.testing.expect(@TypeOf(tag_filter) == TagFilter);
}

test "LOG_TAGS=''" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "",
        .allocator = std.testing.allocator,
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.untagged);
    try std.testing.expect(tag_filter.exclude_list.len == 0);
    try std.testing.expect(tag_filter.include_list.len == 0);
}

test "LOG_TAGS='some_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag",
        .allocator = std.testing.allocator,
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.no_match);

    try std.testing.expect(tag_filter.include_list.len == 1);
    try std.testing.expect(tag_filter.include_list[0] == TagFilter.digest("some_tag"));
}

test "LOG_TAGS='some_tag,other_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag,other_tag",
        .allocator = std.testing.allocator,
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.no_match);

    try std.testing.expect(tag_filter.include_list.len == 2);
    try std.testing.expect(tag_filter.include_list[0] == TagFilter.digest("some_tag"));
    try std.testing.expect(tag_filter.include_list[1] == TagFilter.digest("other_tag"));
}

test "LOG_TAGS='-some_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "-some_tag",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.no_match);

    try std.testing.expect(tag_filter.exclude_list.len == 1);
    try std.testing.expect(tag_filter.exclude_list[0] == TagFilter.digest("some_tag"));
}

test "LOG_TAGS='some_tag,-other_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag,-other_tag",
        .allocator = std.testing.allocator,
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.include_list.len == 1);
    try std.testing.expect(tag_filter.include_list[0] == TagFilter.digest("some_tag"));

    try std.testing.expect(tag_filter.exclude_list.len == 1);
    try std.testing.expect(tag_filter.exclude_list[0] == TagFilter.digest("other_tag"));

}

test "LOG_TAGS='_untagged'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "_untagged",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.untagged);
    try std.testing.expect(tag_filter.include_list.len == 0);
    try std.testing.expect(tag_filter.exclude_list.len == 0);
}

test "LOG_TAGS='some_tag,_untagged,-other_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag,_untagged,-other_tag",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.untagged);
    try std.testing.expect(tag_filter.include_list.len == 1);
    try std.testing.expect(tag_filter.exclude_list.len == 1);
}

test "LOG_TAGS='_all'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "_all",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.override);
}

test "LOG_TAGS='some_tag,-other_tag,_all,yet_another_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag,-other_tag,_all,yet_another_tag",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.override);
}

test "LOG_TAGS='_not_excluded'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "_not_excluded",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.match);
    try std.testing.expect(tag_filter.include_list.len == 0);
    try std.testing.expect(tag_filter.exclude_list.len == 0);
}

test "LOG_TAGS='some_tag,-other_tag,_not_excluded,yet_another_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "some_tag,-other_tag,_not_excluded,yet_another_tag",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.state == TagFilter.State.match);
    try std.testing.expect(tag_filter.include_list.len == 2);
    try std.testing.expect(tag_filter.exclude_list.len == 1);
}

test "LOG_TAGS='_unknown_special_tag'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "_unknown_special_tag",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.include_list.len == 0);
}

test "LOG_TAGS='-'" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = "-",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.include_list.len == 0);
    try std.testing.expect(tag_filter.exclude_list.len == 0);
}

test "Tokenization" {
    var tag_filter = try TagFilter.build(.{
        .log_tags = ",  ,,,  ,, ,some_tag,, ,, ,, other_tag  ,,",
        .allocator = std.testing.allocator
    });
    defer tag_filter.destroy();

    try std.testing.expect(tag_filter.include_list.len == 2);
    try std.testing.expect(tag_filter.include_list[0] == TagFilter.digest("some_tag"));
    try std.testing.expect(tag_filter.include_list[1] == TagFilter.digest("other_tag"));
    try std.testing.expect(tag_filter.exclude_list.len == 0);
}
