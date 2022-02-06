const std = @import("std");

pub const Filter = struct {
    logger_level: Level = .info,

    state: State = .untagged,

    exclude_list: []const u64 = &.{},
    include_list: []const u64 = &.{},

    allocator: ?std.mem.Allocator = null,

    pub const UnknownLogLevelError = error.UnknownLogLevel;

    const BuildError = error {
        UnknownLogLevel,
        OutOfMemory,
    } || std.process.GetEnvVarOwnedError;

    const BuildArguments = struct {
        log_level: ?[]const u8 = null,
        log_tags: ?[]const u8 = null,
        allocator: std.mem.Allocator = std.heap.page_allocator,
    };
    pub fn build(args: BuildArguments) BuildError!Filter {
        const allocator = args.allocator;

        const log_level_str = args.log_level orelse env_var: {
            if (try std.process.hasEnvVar(allocator, "LOG_LEVEL")) {
                break :env_var try std.process.getEnvVarOwned(allocator, "LOG_LEVEL");
            } else {
                break :env_var Defaults.log_level;
            }
        };

        const logger_level = level: {
            if (std.mem.eql(u8, log_level_str, "err")) {
                return UnknownLogLevelError;
            } else if (std.mem.eql(u8, log_level_str, "error")) {
                break :level .err;
            } else {
                break :level std.meta.stringToEnum(Level, log_level_str)
                    orelse return UnknownLogLevelError;
            }
        };

        const log_tags = args.log_tags orelse env_var: {
            if (try std.process.hasEnvVar(allocator, "LOG_TAGS")) {
                break :env_var try std.process.getEnvVarOwned(allocator, "LOG_TAGS");
            } else {
                break :env_var Defaults.log_tags;
            }
        };

        var initial_state: State = if (log_tags.len == 0) .untagged else .no_match;

        var include_list = std.ArrayList(u64).init(allocator);
        var exclude_list = std.ArrayList(u64).init(allocator);

        var iterator = std.mem.tokenize(u8, log_tags, ", ");

        while (iterator.next()) |tag| {
            if (tag[0] == '_') {
                if (std.mem.eql(u8, tag, "_all")) {
                    initial_state = .override;
                    break;
                } else if (std.mem.eql(u8, tag, "_not_excluded")) {
                    initial_state = .match;
                } else if (std.mem.eql(u8, tag, "_untagged") and initial_state != .match) {
                    initial_state = .untagged;
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

        return Filter{
            .logger_level = logger_level,
            .state = initial_state,
            .include_list = include_list.items,
            .exclude_list = exclude_list.items,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *Filter) void {
        if (self.allocator) |allocator| {
            allocator.free(self.include_list);
            allocator.free(self.exclude_list);
        }
    }

    pub fn write_predicate(self: Filter, message_level: Level, tag_digests: []const u64) bool {
        if (@enumToInt(message_level) > @enumToInt(self.logger_level)) {
            return false;
        }

        var state = self.state;

        if (state == .override) {
            return true;
        }

        for (tag_digests) |tag_digest| {
            state = next_state(tag_digest, state, self.include_list, self.exclude_list);

            if (state == .override) {
                return true;
            }
        }

        if (state == .no_match or state == .exclude) {
            return false;
        } else {
            return true;
        }
    }

    pub fn specialize(self: Filter, tags: []const []const u8) Filter {
        var filter = Filter{
            .state = self.state,
            .include_list = self.include_list,
            .exclude_list = self.exclude_list,
        };

        for (tags) |tag| {
            const tag_digest = digest(tag);
            filter.apply(tag_digest);
        }

        return filter;
    }

    pub fn apply(self: *Filter, tag_digest: u64) void {
        self.state = next_state(tag_digest, self.state, self.include_list, self.exclude_list);
    }

    fn next_state(tag_digest: u64, state: State, include_list: []const u64, exclude_list: []const u64) State {
        if (state == .override) {
            return .override;
        } else if (tag_digest == override_digest or tag_digest == override_short_digest) {
            return .override;
        }

        if (state == .exclude) {
            return .exclude;
        } else {
            for (exclude_list) |exclude_digest| {
                if (tag_digest == exclude_digest) {
                    return .exclude;
                }
            }
        }

        if (state == .match) {
            return .match;
        } else {
            for (include_list) |include_digest| {
                if (tag_digest == include_digest) {
                    return .match;
                }
            }
        }

        return .no_match;
    }

    // TODO: Research a more appropriate hashing algorithm or seed
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

    pub const Level = enum(isize) {
        _none = -1,
        fatal,
        err,
        warn,
        info,
        debug,
        trace,
    };

    pub const Defaults = .{
        .log_level = "info",
        .log_tags = "",
    };
};
