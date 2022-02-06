const std = @import("std");

const Filter = @import("log").Filter;

test "Digest" {
    const digest_1: u64 = Filter.digest("some_tag");
    const digest_2: u64 = Filter.digest("some_tag");
    const digest_3: u64 = Filter.digest("other_tag");

    try std.testing.expect(digest_1 == digest_2);
    try std.testing.expect(digest_1 != digest_3);
}
