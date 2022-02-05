const std = @import("std");

const TagFilter = @import("log").Filter.TagFilter;

test "Digest" {
    const digest_1: u64 = TagFilter.digest("some_tag");
    const digest_2: u64 = TagFilter.digest("some_tag");
    const digest_3: u64 = TagFilter.digest("other_tag");

    try std.testing.expect(digest_1 == digest_2);
    try std.testing.expect(digest_1 != digest_3);
}
