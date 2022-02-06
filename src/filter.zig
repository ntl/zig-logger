const std = @import("std");

const Level = @import("./level.zig").Level;

pub const Filter = struct {
    logger_level: Level = .info,

    tag_state: TagState = .untagged,

    exclude_tags: []const u64 = &.{},
    include_tags: []const u64 = &.{},

    allocator: ?std.mem.Allocator = null,

    pub const UnknownLogLevelError = error.UnknownLogLevel;

    const BuildError = error {
        UnknownLogLevel,
        OutOfMemory,
    } || std.process.GetEnvVarOwnedError;

    const BuildArguments = struct {
        logger_level: ?[]const u8 = null,
        logger_tags: ?[]const u8 = null,
        allocator: std.mem.Allocator = std.heap.page_allocator,
    };

    pub fn build(args: BuildArguments) BuildError!Filter {
        const allocator = args.allocator;

        const log_level_str = args.logger_level orelse env_var: {
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

        const logger_tags = args.logger_tags orelse env_var: {
            if (try std.process.hasEnvVar(allocator, "LOG_TAGS")) {
                break :env_var try std.process.getEnvVarOwned(allocator, "LOG_TAGS");
            } else {
                break :env_var Defaults.log_tags;
            }
        };

        var initial_tag_state: TagState = if (logger_tags.len == 0) .untagged else .no_match;

        var include_tags = std.ArrayList(u64).init(allocator);
        var exclude_tags = std.ArrayList(u64).init(allocator);

        var tag_iterator = std.mem.tokenize(u8, logger_tags, ", ");

        while (tag_iterator.next()) |tag| {
            if (tag[0] == '_') {
                if (std.mem.eql(u8, tag, "_all")) {
                    initial_tag_state = .override;
                    break;
                } else if (std.mem.eql(u8, tag, "_not_excluded")) {
                    initial_tag_state = .match;
                } else if (std.mem.eql(u8, tag, "_untagged") and initial_tag_state != .match) {
                    initial_tag_state = .untagged;
                }
            } else if (tag[0] == '-') {
                if (tag.len > 1) {
                    const digest = tag_digest(tag[1..]);
                    try exclude_tags.append(digest);
                }
            } else {
                const digest = tag_digest(tag);
                try include_tags.append(digest);
            }
        }

        return Filter{
            .logger_level = logger_level,
            .tag_state = initial_tag_state,
            .include_tags = include_tags.items,
            .exclude_tags = exclude_tags.items,
            .allocator = allocator,
        };
    }

    pub fn destroy(self: *Filter) void {
        if (self.allocator) |allocator| {
            allocator.free(self.include_tags);
            allocator.free(self.exclude_tags);
        }
    }

    pub fn write_predicate(self: Filter, message_level: Level, tag_digests: []const u64) bool {
        if (@enumToInt(message_level) > @enumToInt(self.logger_level)) {
            return false;
        }

        var tag_state = self.tag_state;

        if (tag_state == .override) {
            return true;
        }

        for (tag_digests) |digest| {
            tag_state = next_tag_state(digest, tag_state, self.include_tags, self.exclude_tags);

            if (tag_state == .override) {
                return true;
            }
        }

        if (tag_state == .no_match or tag_state == .exclude) {
            return false;
        } else {
            return true;
        }
    }

    pub fn specialize(self: Filter, tags: []const []const u8) Filter {
        var filter = Filter{
            .logger_level = self.logger_level,
            .tag_state = self.tag_state,
            .include_tags = self.include_tags,
            .exclude_tags = self.exclude_tags,
        };

        for (tags) |tag| {
            const digest = tag_digest(tag);
            filter.apply_tag(digest);
        }

        return filter;
    }

    pub fn apply_tag(self: *Filter, digest: u64) void {
        self.tag_state = next_tag_state(
            digest,
            self.tag_state,
            self.include_tags,
            self.exclude_tags,
        );
    }

    fn next_tag_state(digest: u64, tag_state: TagState, include_tags: []const u64, exclude_tags: []const u64) TagState {
        if (tag_state == .override) {
            return .override;
        } else if (digest == override_digest or digest == override_short_digest) {
            return .override;
        }

        if (tag_state == .exclude) {
            return .exclude;
        } else {
            for (exclude_tags) |exclude_digest| {
                if (digest == exclude_digest) {
                    return .exclude;
                }
            }
        }

        if (tag_state == .match) {
            return .match;
        } else {
            for (include_tags) |include_digest| {
                if (digest == include_digest) {
                    return .match;
                }
            }
        }

        return .no_match;
    }

    // TODO: Research a more appropriate hashing algorithm or seed
    const tag_digest_hash_seed = 0;
    pub fn tag_digest(tag: []const u8) u64 {
        return std.hash.Wyhash.hash(tag_digest_hash_seed, tag);
    }

    const override_digest = tag_digest("_override");
    const override_short_digest = tag_digest("*");

    pub const TagState = enum {
        untagged,
        no_match,
        match,
        exclude,
        override,
    };

    pub const Defaults = .{
        .log_level = "info",
        .log_tags = "",
    };
};
