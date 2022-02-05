const std = @import("std");

pub const TagFilter = struct {
    state: State = State.untagged,

    exclude_list: []const u64 = &.{},
    include_list: []const u64 = &.{},

    allocator: ?std.mem.Allocator = null,

    const BuildArguments = struct {
        log_tags: ?[]const u8 = null,
        allocator: std.mem.Allocator = std.heap.page_allocator,
    };
    pub fn build(args: BuildArguments) !TagFilter {
        const allocator = args.allocator;

        const log_tags = args.log_tags orelse env_var: {
            if (try std.process.hasEnvVar(allocator, "LOG_TAGS")) {
                break :env_var try std.process.getEnvVarOwned(allocator, "LOG_TAGS");
            } else {
                break :env_var "";
            }
        };

        if (log_tags.len == 0) {
            return TagFilter{};
        }

        var initial_state = State.no_match;

        var include_list = std.ArrayList(u64).init(allocator);
        var exclude_list = std.ArrayList(u64).init(allocator);

        var iterator = std.mem.tokenize(u8, log_tags, ", ");

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
                    const tag_digest = digest(tag[1..]);
                    try exclude_list.append(tag_digest);
                }
            } else {
                const tag_digest = digest(tag);
                try include_list.append(tag_digest);
            }
        }

        return TagFilter{
            .state = initial_state,
            .include_list = include_list.items,
            .exclude_list = exclude_list.items,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *TagFilter) void {
        if (self.allocator) |allocator| {
            allocator.free(self.include_list);
            allocator.free(self.exclude_list);
        }
    }

    pub fn specialize(self: TagFilter, tags: []const []const u8) TagFilter {
        var tag_filter = TagFilter{
            .state = self.state,
            .include_list = self.include_list,
            .exclude_list = self.exclude_list,
        };

        for (tags) |tag| {
            tag_filter.addTag(tag);
        }

        return tag_filter;
    }

    fn addTag(self: *TagFilter, tag: []const u8) void {
        const tag_digest = digest(tag);

        self.state = self.nextState(tag_digest);
    }

    pub fn nextState(self: TagFilter, tag_digest: u64) State {
        if (self.state == State.override) {
            return State.override;
        } else if (tag_digest == override_digest or tag_digest == override_short_digest) {
            return State.override;
        }

        if (self.state == State.exclude) {
            return State.exclude;
        } else {
            for (self.exclude_list) |exclude_digest| {
                if (tag_digest == exclude_digest) {
                    return State.exclude;
                }
            }
        }

        if (self.state == State.match) {
            return State.match;
        } else {
            for (self.include_list) |include_digest| {
                if (tag_digest == include_digest) {
                    return State.match;
                }
            }
        }

        return State.no_match;
    }

    const digest_hash_seed = 0;
    pub fn digest(tag: []const u8) u64 {
        return std.hash.Wyhash.hash(digest_hash_seed, tag);
    }

    const override_digest = digest("_override");
    const override_short_digest = digest("*");

    pub const State = enum {
        untagged,
        no_match,
        match,
        exclude,
        override,
    };
};
