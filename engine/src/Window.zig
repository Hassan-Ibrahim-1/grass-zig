const std = @import("std");
const glfw = @import("glfw");
const Allocator = std.mem.Allocator;
const gl = @import("gl");

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
glfw_window: glfw.Window,
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
    var glfw_window = glfw.Window.create(width, height, name, null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }) orelse return error.GlfwInitfailed;

    glfw.makeContextCurrent(glfw_window);
    var gl_procs = try allocator.create(gl.ProcTable);
    if (!gl_procs.init(glfw.getProcAddress)) {
        return error.GlInitFailed;
    }

    gl.makeProcTableCurrent(gl_procs);

    glfw_window.setFramebufferSizeCallback(framebufferSizeCallback);

    return .{
        .allocator = allocator,
        .width = width,
        .height = height,
        .name = name,
        .glfw_window = glfw_window,
        .gl_procs = gl_procs,
    };
}

pub fn deinit(self: *Window) void {
    self.allocator.destroy(self.gl_procs);
    self.glfw_window.destroy();
    glfw.makeContextCurrent(null);
    gl.makeProcTableCurrent(null);
}

fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

pub fn swapBuffers(self: *Window) void {
    const size = self.glfw_window.getSize();
    self.width = size.width;
    self.height = size.height;
    self.glfw_window.swapBuffers();
}

pub fn shouldClose(self: *Window) bool {
    return self.glfw_window.shouldClose();
}

pub fn setShouldClose(self: *Window, value: bool) void {
    self.glfw_window.setShouldClose(value);
}

pub fn getKey(self: *Window, key: glfw.Key) glfw.Action {
    return self.glfw_window.getKey(key);
}
