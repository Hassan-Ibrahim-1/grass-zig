const std = @import("std");
const log = @import("log.zig");
const engine = @import("engine.zig");
const math = @import("math.zig");
const glfw = @import("glfw");
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Mat4 = math.Mat4;
const Allocator = std.mem.Allocator;
const Transform = @import("Transform.zig");
const Camera = @import("Camera.zig");

const start_key_index: u32 = @intFromEnum(glfw.Key.space);
const max_keys: u32 = @as(u32, @intFromEnum(glfw.Key.last())) + 1;

const KeyCallbackFn = *const fn (key: Key, action: KeyAction) void;

pub const Key = glfw.Key;
pub const KeyAction = enum {
    press,
    release,
};

pub const MouseButton = enum {
    any,
    right,
    left,
};

var alloc: Allocator = undefined;

// TODO: wrap this in a state struct

/// stored as normalized device coordinates
var mouse_pos = Vec2.fromValue(0);
var last_mouse_pos = Vec2.fromValue(0);
var first_mouse = true;

var scroll_delta = Vec2.fromValue(0);

var lmb_down = false;
var lmb_clicked = false;
var lmb_released = false;
var rmb_down = false;
var rmb_clicked = false;
var rmb_released = false;

var key_pressed = [_]bool{false} ** max_keys;
var key_released = [_]bool{false} ** max_keys;
var key_down = [_]bool{false} ** max_keys;

var user_key_callbacks: std.ArrayList(KeyCallbackFn) = undefined;

var camera: *Camera = undefined;
var window: glfw.Window = undefined;

pub fn init(allocator: Allocator) void {
    alloc = allocator;
    user_key_callbacks = std.ArrayList(KeyCallbackFn).init(alloc);

    camera = engine.camera();
    window = engine.window().glfw_window;
    setCallbacks();

    // keys appear to be set to true initially?
    // thats why this is here
    updateKeys();
}

pub fn deinit() void {
    user_key_callbacks.deinit();
}

fn setCallbacks() void {
    window.setKeyCallback(keyCallback);
    window.setCursorPosCallback(mouseMovementCallback);
    window.setScrollCallback(mouseScrollCallback);
    window.setMouseButtonCallback(mouseButtonCallback);
}

pub fn startFrame() void {
    glfw.pollEvents();
    updateKeys();

    const dt = engine.deltaTime();

    if (window.getKey(.w) == .press) {
        camera.processKeyboard(.forward, dt);
    }
    if (window.getKey(.a) == .press) {
        camera.processKeyboard(.left, dt);
    }
    if (window.getKey(.s) == .press) {
        camera.processKeyboard(.backward, dt);
    }
    if (window.getKey(.d) == .press) {
        camera.processKeyboard(.right, dt);
    }
    if (window.getKey(.q) == .press) {
        camera.processKeyboard(.down, dt);
    }
    if (window.getKey(.e) == .press) {
        camera.processKeyboard(.up, dt);
    }
}

pub fn endFrame() void {
    updateMouseButtons();
}

/// normalized between 0.0 and 1.0
pub fn getNdcMousePos() Vec2 {
    return mouse_pos;
}

pub fn getScrollDelta() Vec2 {
    return scroll_delta;
}

/// mouse pos in screen space
pub fn getMousePos() Vec2 {
    // convert ndc mouse coords to world space
    const mouse_ndc = Vec4.init(mouse_pos.x, mouse_pos.y, 0.0, 1.0);
    const inverse_view = camera.getViewMatrix().inverse();
    const world_space = inverse_view.mulVec4(mouse_ndc);
    return Vec2.fromVec4(world_space);
}

pub fn mouseButtonDown(button: MouseButton) bool {
    if (button == .any) {
        return lmb_down or rmb_down;
    } else if (button == .left) {
        return lmb_down;
    } else if (button == .right) {
        return rmb_down;
    }
    return false;
}

pub fn mouseButtonClicked(button: MouseButton) bool {
    if (button == .any) {
        return lmb_clicked or rmb_clicked;
    } else if (button == .left) {
        return lmb_clicked;
    } else if (button == .right) {
        return rmb_clicked;
    }
    return false;
}

pub fn mouseButtonReleased(button: MouseButton) bool {
    if (button == .any) {
        return lmb_released or rmb_released;
    } else if (button == .left) {
        return lmb_released;
    } else if (button == .right) {
        return rmb_released;
    }
    return false;
}

pub fn addKeyCallback(callback: KeyCallbackFn) void {
    user_key_callbacks.append(callback) catch @panic("allocation failed");
}

pub fn keyPressed(key: Key) bool {
    return key_pressed[@intCast(@intFromEnum(key))];
}

pub fn keyReleased(key: Key) bool {
    return key_released[@intCast(@intFromEnum(key))];
}

pub fn keyDown(key: Key) bool {
    return key_down[@intCast(@intFromEnum(key))];
}

fn updateMouseButtons() void {
    lmb_clicked = false;
    lmb_released = false;
    rmb_clicked = false;
    rmb_released = false;
}

fn updateKeys() void {
    // where keys start?
    var i: usize = 32;
    while (i < max_keys) : (i += 1) {
        key_pressed[i] = false;
        key_released[i] = false;

        // weird hack. had to modify mach-glfw to make the c functions accessible
        // window.getKey(@enumFromtInt(i)) wasn't working
        const key: glfw.Action = @enumFromInt(glfw.c.glfwGetKey(window.handle, @intCast(i)));
        const down = key == .press;
        if (!key_down[i] and down) {
            key_pressed[i] = true;
        } else if (key_down[i] and !down) {
            key_released[i] = true;
        }
        key_down[i] = down;
    }
}

fn keyCallback(
    win: glfw.Window,
    key: glfw.Key,
    scancode: i32,
    action: glfw.Action,
    mods: glfw.Mods,
) void {
    _ = mods;
    _ = scancode;

    if ((key == .escape) and action == .press) {
        win.setShouldClose(true);
    }

    for (user_key_callbacks.items) |callback| {
        const key_action: KeyAction = value: {
            if (keyPressed(key)) break :value .press;
            if (keyReleased(key)) break :value .release;
            unreachable;
        };
        callback(key, key_action);
    }

    // else if ((key == .o) and action == .press) {
    // log.info("reloading shaders", .{});
    // shader.reload() catch |err| {
    //     log.err(
    //         "failed to reload shader with paths: \n{s}\n{s} error: {}",
    //         .{ shader.vertex_path, shader.fragment_path, err },
    //     );
    // };
    // }
}

fn mouseMovementCallback(
    win: glfw.Window,
    posx: f64,
    posy: f64,
) void {
    const size = win.getSize();
    const viewport = Vec4.init(
        0,
        0,
        @floatFromInt(size.width),
        @floatFromInt(size.height),
    );
    const w = Vec3.init(@floatCast(posx), @floatCast(posy), 0);
    const real_pos = math.unProject(
        w,
        &Mat4.identity(),
        &Mat4.identity(),
        viewport,
    );
    mouse_pos.x = real_pos.x;
    mouse_pos.y = -real_pos.y;
    if (first_mouse) {
        last_mouse_pos.x = @floatCast(posx);
        last_mouse_pos.y = @floatCast(posy);
        first_mouse = false;
    }

    if (!engine.cursorEnabled()) {
        const x_offset = @as(f32, @floatCast(posx)) - last_mouse_pos.x;
        const y_offset = @as(f32, @floatCast(posy)) - last_mouse_pos.y;
        camera.processMouseMovement(x_offset, y_offset, true, false);
    }

    last_mouse_pos.x = @floatCast(posx);
    last_mouse_pos.y = @floatCast(posy);
}

fn mouseScrollCallback(
    win: glfw.Window,
    xoffset: f64,
    yoffset: f64,
) void {
    _ = win;
    scroll_delta = Vec2.init(
        @floatCast(xoffset),
        @floatCast(yoffset),
    );
    camera.processMouseScroll(@floatCast(yoffset));
}

fn mouseButtonCallback(win: glfw.Window, button: glfw.MouseButton, action: glfw.Action, mods: glfw.Mods) void {
    _ = win;
    _ = mods;
    if (button == .left) {
        if (action == .press) {
            lmb_down = true;
            lmb_clicked = true;
            lmb_released = false;
        } else if (action == .release) {
            lmb_down = false;
            lmb_clicked = false;
            lmb_released = true;
        }
    } else if (button == .right) {
        if (action == .press) {
            rmb_down = true;
            rmb_clicked = true;
            rmb_released = false;
        } else if (action == .release) {
            rmb_down = false;
            rmb_clicked = false;
            rmb_released = true;
        }
    }
}
