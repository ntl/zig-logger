const std = @import("std");

const Filter = @import("log").Filter;

test "No LOG_TAGS" {
    var filter = try Filter.build(.{
        .logger_tags = null,
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .untagged);
    try std.testing.expect(filter.exclude_tags.len == 0);
    try std.testing.expect(filter.include_tags.len == 0);
}

test "LOG_TAGS='some_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .no_match);

    try std.testing.expect(filter.include_tags.len == 1);
    try std.testing.expect(filter.include_tags[0] == Filter.tag_digest("some_tag"));
}

test "LOG_TAGS='some_tag,other_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag,other_tag",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .no_match);

    try std.testing.expect(filter.include_tags.len == 2);
    try std.testing.expect(filter.include_tags[0] == Filter.tag_digest("some_tag"));
    try std.testing.expect(filter.include_tags[1] == Filter.tag_digest("other_tag"));
}

test "LOG_TAGS='-some_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "-some_tag",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .no_match);

    try std.testing.expect(filter.exclude_tags.len == 1);
    try std.testing.expect(filter.exclude_tags[0] == Filter.tag_digest("some_tag"));
}

test "LOG_TAGS='some_tag,-other_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag,-other_tag",
        .allocator = std.testing.allocator,
    });
    defer filter.destroy();

    try std.testing.expect(filter.include_tags.len == 1);
    try std.testing.expect(filter.include_tags[0] == Filter.tag_digest("some_tag"));

    try std.testing.expect(filter.exclude_tags.len == 1);
    try std.testing.expect(filter.exclude_tags[0] == Filter.tag_digest("other_tag"));

}

test "LOG_TAGS='_untagged'" {
    var filter = try Filter.build(.{
        .logger_tags = "_untagged",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .untagged);
    try std.testing.expect(filter.include_tags.len == 0);
    try std.testing.expect(filter.exclude_tags.len == 0);
}

test "LOG_TAGS='some_tag,_untagged,-other_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag,_untagged,-other_tag",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .untagged);
    try std.testing.expect(filter.include_tags.len == 1);
    try std.testing.expect(filter.exclude_tags.len == 1);
}

test "LOG_TAGS='_all'" {
    var filter = try Filter.build(.{
        .logger_tags = "_all",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .override);
}

test "LOG_TAGS='some_tag,-other_tag,_all,yet_another_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag,-other_tag,_all,yet_another_tag",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .override);
}

test "LOG_TAGS='_not_excluded'" {
    var filter = try Filter.build(.{
        .logger_tags = "_not_excluded",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .match);
    try std.testing.expect(filter.include_tags.len == 0);
    try std.testing.expect(filter.exclude_tags.len == 0);
}

test "LOG_TAGS='some_tag,-other_tag,_not_excluded,yet_another_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "some_tag,-other_tag,_not_excluded,yet_another_tag",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.tag_state == .match);
    try std.testing.expect(filter.include_tags.len == 2);
    try std.testing.expect(filter.exclude_tags.len == 1);
}

test "LOG_TAGS='_unknown_special_tag'" {
    var filter = try Filter.build(.{
        .logger_tags = "_unknown_special_tag",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.include_tags.len == 0);
}

test "LOG_TAGS='-'" {
    var filter = try Filter.build(.{
        .logger_tags = "-",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.include_tags.len == 0);
    try std.testing.expect(filter.exclude_tags.len == 0);
}

test "Tokenization" {
    var filter = try Filter.build(.{
        .logger_tags = ",  ,,,  ,, ,some_tag,, ,, ,, other_tag  ,,",
        .allocator = std.testing.allocator
    });
    defer filter.destroy();

    try std.testing.expect(filter.include_tags.len == 2);
    try std.testing.expect(filter.include_tags[0] == Filter.tag_digest("some_tag"));
    try std.testing.expect(filter.include_tags[1] == Filter.tag_digest("other_tag"));
    try std.testing.expect(filter.exclude_tags.len == 0);
}
