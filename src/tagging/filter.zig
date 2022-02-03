const Digest = @import("./digest.zig");

pub const Filter = struct {
    pub const State = enum { untagged, match_needed, matched, excluded, print };
    state: State = State.untagged,

    exclude_list: []const u64 = &.{},
    include_list: []const u64 = &.{},

    const override_digest = Digest.tag("_override");
    const override_short_digest = Digest.tag("*");

    pub fn init() Filter {
        return Filter{};
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
};
