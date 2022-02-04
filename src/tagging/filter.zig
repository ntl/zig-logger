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
        var initial_state = if (log_tags_setting.len == 0) State.untagged else State.no_match;

        var include_list = std.ArrayList(u64).init(allocator);
        var exclude_list = std.ArrayList(u64).init(allocator);

        var iterator = std.mem.tokenize(u8, log_tags_setting, ", ");

        while (iterator.next()) |tag| {
            if (tag[0] == '_') {
                if (std.mem.eql(u8, tag, "_all")) {
                    include_list.shrinkAndFree(0);
                    exclude_list.shrinkAndFree(0);
                    initial_state = State.override;
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

    pub fn specialize(self: Filter, tags: []const []const u8) Filter {
        var filter = Filter {
            .state = self.state,
            .include_list = self.include_list,
            .exclude_list = self.exclude_list
        };

        for (tags) |tag| {
            filter.addTag(tag);
        }

        return filter;
    }

    fn addTag(self: *Filter, tag: []const u8) void {
        const digest = Digest.tag(tag);

        self.state = self.nextState(digest);
    }

    pub fn nextState(self: Filter, digest: u64) State {
        if (self.state == State.override) {
            return State.override;
        } else if (digest == override_digest or digest == override_short_digest) {
            return State.override;
        }

        if (self.state == State.exclude) {
            return State.exclude;
        } else {
            for (self.exclude_list) |exclude_digest| {
                if (digest == exclude_digest) {
                    return State.exclude;
                }
            }
        }

        if (self.state == State.match) {
            return State.match;
        } else {
            for (self.include_list) |include_digest| {
                if (digest == include_digest) {
                    return State.match;
                }
            }
        }

        return State.no_match;
    }

    const override_digest = Digest.tag("_override");
    const override_short_digest = Digest.tag("*");

    pub const State = enum { untagged, no_match, match, exclude, override };
};
