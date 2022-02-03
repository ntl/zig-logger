const std = @import("std");

const hash_seed = 0;

pub fn tag(string: []const u8) u64 {
    return std.hash.Wyhash.hash(hash_seed, string);
}

pub fn tags(comptime strings: anytype) []const u64 {
    comptime var ary: [strings.len]u64 = .{0} ** strings.len;

    comptime {
        for (strings) |string, index| {
            ary[index] = tag(string);
        }
    }

    return &ary;
}
