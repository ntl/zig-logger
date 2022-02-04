const std = @import("std");

const Digest = @import("./digest.zig");

pub const Filter = struct {
    state: State = State.untagged,

    exclude_list: []const u64 = &.{},
    include_list: []const u64 = &.{},

    allocator: ?std.mem.Allocator = null,

    pub fn build() !Filter {
        const allocator = std.heap.page_allocator;

        const log_tags_setting_set = try std.process.hasEnvVar(allocator, "LOG_TAGS");
        const log_tags_setting = if (log_tags_setting_set) try std.process.getEnvVarOwned(allocator, "LOG_TAGS") else "";

        if (init(log_tags_setting, allocator)) |filter| {
            return filter;
        } else |err| {
            return err;
        }
    }

    pub fn init(log_tags_setting: []const u8, allocator: std.mem.Allocator) error{OutOfMemory}!Filter {
        var initial_state = if (log_tags_setting.len == 0) State.untagged else State.match_needed;

        var include_list = std.ArrayList(u64).init(allocator);
        var exclude_list = std.ArrayList(u64).init(allocator);

        var iterator = std.mem.tokenize(u8, log_tags_setting, ", ");

        while (iterator.next()) |tag| {
            if (tag[0] == '_') {
                if (std.mem.eql(u8, tag, "_all")) {
                    include_list.shrinkAndFree(0);
                    exclude_list.shrinkAndFree(0);
                    initial_state = State.print;
                    break;
                } else if (std.mem.eql(u8, tag, "_untagged")) {
                    initial_state = State.untagged;
                }
            } else if (tag[0] == '-') {
                if (tag.len > 1) {
                    const tag_digest = Digest.tag(tag[1..]);
                    try exclude_list.append(tag_digest);
                }
            } else {
                const tag_digest = Digest.tag(tag);
                try include_list.append(tag_digest);
            }
        }

        return Filter{ .state = initial_state, .include_list = include_list.items, .exclude_list = exclude_list.items, .allocator = allocator };
    }

    pub fn deinit(self: *Filter) void {
        if (self.allocator) |allocator| {
            allocator.free(self.include_list);
            allocator.free(self.exclude_list);
        }
    }

    pub fn addTag(self: *Filter, digest: u64) void {
        self.state = self.nextState(digest);
    }

    pub fn nextState(self: Filter, digest: u64) State {
        if (self.state == State.print) {
            return State.print;
        } else if (digest == override_digest or digest == override_short_digest) {
            return State.print;
        }

        if (self.state == State.excluded) {
            return State.excluded;
        } else {
            for (self.exclude_list) |exclude_digest| {
                if (digest == exclude_digest) {
                    return State.excluded;
                }
            }
        }

        if (self.state == State.matched) {
            return State.matched;
        } else {
            for (self.include_list) |include_digest| {
                if (digest == include_digest) {
                    return State.matched;
                }
            }
        }

        return State.match_needed;
    }

    const override_digest = Digest.tag("_override");
    const override_short_digest = Digest.tag("*");

    pub const State = enum { untagged, match_needed, matched, excluded, print };
};
