pub const Tagging = struct {
    pub const Digest = @import("./tagging/digest.zig");

    pub usingnamespace @import("./tagging/filter.zig");
};
