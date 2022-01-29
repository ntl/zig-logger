const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const library_name = "log";
    const root_src = "src/log.zig";

    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary(library_name, root_src);
    lib.setBuildMode(mode);
    lib.install();

    const zig_files = [_][]const u8{ "src", "test", "build.zig" };
    var fmt = b.addFmt(&zig_files);
    const update_formatting = b.step("update-formatting", "Update source formatting (zig fmt)");
    update_formatting.dependOn(&fmt.step);

    var tests = b.addTest("test/automated.zig");
    tests.setBuildMode(mode);
    tests.setTarget(target);
    tests.addPackagePath(library_name, root_src);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);
}
