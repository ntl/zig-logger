const std = @import("std");

const Log = @import("log");
const Digest = Log.Tagging.Digest;

test "Digest" {
    const digest_1: u64 = Digest.tag("some_tag");
    const digest_2: u64 = Digest.tag("some_tag");
    const digest_3: u64 = Digest.tag("other_tag");

    try std.testing.expectEqual(digest_1, digest_2);
    try std.testing.expect(digest_1 != digest_3);
}

test "Digests, From Tuple" {
    const digests = Digest.tags(.{ "some_tag", "other_tag", "yet_another_tag" });

    try std.testing.expectEqual(digests.len, 3);
    try std.testing.expectEqual(digests[0], Digest.tag("some_tag"));
    try std.testing.expectEqual(digests[1], Digest.tag("other_tag"));
    try std.testing.expectEqual(digests[2], Digest.tag("yet_another_tag"));
}

