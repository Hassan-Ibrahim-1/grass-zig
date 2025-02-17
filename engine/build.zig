const std = @import("std");
const cimgui = @import("cimgui.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const name = "engine";
    const root = b.path("src/engine.zig");

    const engine = b.addModule(name, .{
        .root_source_file = root,
        .target = target,
        .optimize = optimize,
    });

    // Use mach-glfw
    const glfw_dep = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
    });
    const glfw_module = glfw_dep.module("mach-glfw");
    engine.addImport("glfw", glfw_module);

    const ft_dep = b.dependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    });
    const ft_mod = ft_dep.module("mach-freetype");
    engine.addImport("freetype", ft_mod);

    const src_files = [_][]const u8{
        "dependencies/stb_image.c",
        "dependencies/cgltf.c",
    };

    engine.addCSourceFiles(.{
        .files = &src_files,
        .flags = &.{"-g"},
    });
    engine.addIncludePath(b.path("dependencies"));

    const cimgui_dep = b.dependency("cimgui.zig", .{
        .target = target,
        .optimize = optimize,
        .platform = cimgui.Platform.GLFW,
        .renderer = cimgui.Renderer.OpenGL3,
    });

    // Where `exe` represents your executable/library to link to
    engine.linkLibrary(cimgui_dep.artifact("cimgui"));

    // gl
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    // Import the generated module.
    engine.addImport("gl", gl_bindings);

    const clay_dep = b.dependency("clay-zig", .{
        .target = target,
        .optimize = optimize,
    });
    const clay_module = clay_dep.module("zclay");
    engine.addImport("clay", clay_module);

    // zig build test
    const exe_unit_tests = b.addTest(.{
        .root_source_file = root,
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    exe_unit_tests.root_module.addImport("glfw", glfw_module);
    exe_unit_tests.root_module.addImport("gl", gl_bindings);
    exe_unit_tests.root_module.addImport("freetype", ft_mod);
    exe_unit_tests.root_module.addImport("clay", clay_module);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // check
    const exe_check = b.addExecutable(.{
        .name = name,
        .root_source_file = root,
        .target = target,
        .optimize = optimize,
    });
    // is there a better way to do this?
    exe_check.root_module.addImport("glfw", glfw_module);
    exe_check.root_module.addImport("gl", gl_bindings);
    exe_check.root_module.addImport("freetype", ft_mod);
    exe_check.root_module.addImport("clay", clay_module);
    exe_check.root_module.addCSourceFiles(.{
        .files = &src_files,
        .flags = &.{"-g"},
    });
    exe_check.root_module.addIncludePath(b.path("dependencies"));
    exe_check.root_module.linkLibrary(cimgui_dep.artifact("cimgui"));
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);
}
