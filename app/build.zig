const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const name = "App";

    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const engine = b.dependency("engine", .{
        .target = target,
        .optimize = optimize,
    });
    const engine_module = engine.module("engine");
    exe.root_module.addImport("engine", engine_module);

    b.installArtifact(exe);

    const module = b.addModule("app", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("engine", engine_module);

    // allows for zig build run
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    // zig build test
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    // check
    const exe_check = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // is there a better way to do this?
    exe_check.root_module.addImport("engine", engine_module);
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);
}
