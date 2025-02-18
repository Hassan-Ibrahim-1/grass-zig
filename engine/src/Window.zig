const std = @import("std");
const Allocator = std.mem.Allocator;
const engine = @import("engine.zig");
const gl = @import("gl");
const glfw = engine.glfw;
const input = engine.input;
const Key = input.Key;
const Action = input.Action;

const Window = @This();

const WindowError = error{
    GlfwInitfailed,
    GlInitFailed,
};

allocator: Allocator,
/// don't mutate this
width: u32,
/// don't mutate this
height: u32,
name: [*:0]const u8,
/// don't mutate this. you can call functions on this. but don't
/// assign it to something else
glfw_window: *glfw.GLFWwindow,
/// don't touch this
gl_procs: *gl.ProcTable,

/// Assumes that glfw.init has already been called
/// this will just create a window and load gl functions
/// nothing more
pub fn init(
    allocator: Allocator,
    width: u32,
    height: u32,
    name: [*:0]const u8,
) !Window {
    const window = glfw.glfwCreateWindow(
        @intCast(width),
        @intCast(height),
        @ptrCast(name),
        null,
        null,
    ) orelse return error.GlfwInitfailed;
    // var glfw_window = glfw.Window.create(width, height, name, null, null, .{
    //     .context_version_major = gl.info.version_major,
    //     .context_version_minor = gl.info.version_minor,
    //     .opengl_profile = .opengl_core_profile,
    //     .opengl_forward_compat = true,
    // }) orelse return error.GlfwInitfailed;

    glfw.glfwMakeContextCurrent(window);
    // glfw.makeContextCurrent(glfw_window);
    var gl_procs = try allocator.create(gl.ProcTable);
    if (!gl_procs.init(glfw.glfwGetProcAddress)) {
        return error.GlInitFailed;
    }

    gl.makeProcTableCurrent(gl_procs);

    _ = glfw.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    return .{
        .allocator = allocator,
        .width = width,
        .height = height,
        .name = name,
        .glfw_window = window,
        .gl_procs = gl_procs,
    };
}

pub fn deinit(self: *Window) void {
    self.allocator.destroy(self.gl_procs);
    glfw.glfwDestroyWindow(self.glfw_window);
    glfw.glfwMakeContextCurrent(null);
    gl.makeProcTableCurrent(null);
}

fn framebufferSizeCallback(
    window: ?*glfw.GLFWwindow,
    width: c_int,
    height: c_int,
) callconv(.C) void {
    _ = window;
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

pub fn swapBuffers(self: *Window) void {
    glfw.glfwGetWindowSize(
        self.glfw_window,
        @ptrCast(&self.width),
        @ptrCast(&self.height),
    );
    // self.width = size.width;
    // self.height = size.height;
    glfw.glfwSwapBuffers(self.glfw_window);
    // self.glfw_window.swapBuffers();
}

pub fn shouldClose(self: *Window) bool {
    return if (glfw.glfwWindowShouldClose(self.glfw_window) != 0) ret: {
        break :ret true;
    } else ret: {
        break :ret false;
    };
}

pub fn setShouldClose(self: *Window, value: bool) void {
    glfw.glfwSetWindowShouldClose(self.glfw_window, if (value) 1 else 0);
    // self.glfw_window.setShouldClose(value);
}

pub fn getKey(self: *Window, key: Key) Action {
    return @enumFromInt(glfw.glfwGetKey(
        self.glfw_window,
        key.toCint(),
    ));
}

pub fn enableCursor(self: *Window, b: bool) void {
    glfw.glfwSetInputMode(
        self.glfw_window,
        glfw.GLFW_CURSOR,
        if (b) glfw.GLFW_CURSOR_NORMAL else glfw.GLFW_CURSOR_DISABLED,
    );
}
