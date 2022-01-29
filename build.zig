const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const library_name = "TEMPLATE_LIBRARY";
    const root_src = "TEMPLATE_ROOT_SRC";

    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary(library_name, root_src);
    lib.setBuildMode(mode);
    lib.install();

    const zig_files = [_][]const u8{ "src", "test", "build.zig" };
    var fmt = b.addFmt(&zig_files);
    const update_formatting = b.step("update-formatting", "Update source formatting (zig fmt)");
    update_formatting.dependOn(&fmt.step);

    var main_tests = b.addTest("test/automated.zig");
    main_tests.addPackagePath(library_name, root_src);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
