const std = @import("std");
const engine = @import("engine.zig");
const ig = engine.ig_raw;
const math = engine.math;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const Color = engine.Color;
const Material = engine.Material;
const RenderItem = engine.RenderItem;
const Transform = engine.Transform;
const Actor = engine.Actor;
const Allocator = std.mem.Allocator;

const State = struct {
    allocator: Allocator,
};

var state: State = undefined;

pub fn init(allocator: Allocator) void {
    state.allocator = allocator;
}

pub fn begin(name: [:0]const u8) void {
    beginEx(name, null, 0);
}

pub fn beginEx(
    name: [:0]const u8,
    open: ?*bool,
    flags: ig.ImGuiWindowFlags,
) void {
    _ = ig.ImGui_Begin(@ptrCast(name), open, flags);
}

pub fn end() void {
    ig.ImGui_End();
}

pub fn dragInt(name: [:0]const u8, i: *i32) bool {
    return ig.ImGui_DragInt(@ptrCast(name), @ptrCast(i));
}

pub fn dragIntEx(
    name: [:0]const u8,
    i: *i32,
    speed: f32,
    vmin: f32,
    vmax: f32,
) bool {
    const min = blk: {
        if (vmin != null) break :blk vmin.?;
        break :blk std.math.floatMin(f32);
    };
    const max = blk: {
        if (vmax != null) break :blk vmax.?;
        break :blk std.math.floatMax(f32);
    };
    ig.ImGui_DragFloatEx(
        @ptrCast(name),
        @ptrCast(i),
        speed,
        min,
        max,
        null,
        0,
    );
}

pub fn dragFloat(name: [:0]const u8, f: *f32) bool {
    return ig.ImGui_DragFloat(@ptrCast(name), f);
}

pub fn dragFloatEx(
    name: [:0]const u8,
    f: *f32,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    const min = blk: {
        if (vmin != null) break :blk vmin.?;
        break :blk std.math.floatMin(f32);
    };
    const max = blk: {
        if (vmax != null) break :blk vmax.?;
        break :blk std.math.floatMax(f32);
    };
    ig.ImGui_DragFloatEx(
        @ptrCast(name),
        @ptrCast(f),
        speed,
        min,
        max,
        null,
        0,
    );
}

pub fn dragFloat2(
    name: [:0]const u8,
    values: [*]f32,
) bool {
    return ig.ImGui_DragFloat2(
        @ptrCast(name),
        @ptrCast(values),
    );
}

pub fn dragFloat2Ex(
    name: [:0]const u8,
    values: [*]f32,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    const min = blk: {
        if (vmin != null) break :blk vmin.?;
        break :blk std.math.floatMin(f32);
    };
    const max = blk: {
        if (vmax != null) break :blk vmax.?;
        break :blk std.math.floatMax(f32);
    };

    return ig.ImGui_DragFloat2Ex(
        @ptrCast(name),
        @ptrCast(values),
        speed,
        max,
        min,
        null,
        0,
    );
}

pub fn dragFloat3(
    name: [:0]const u8,
    values: [*]f32,
) bool {
    return ig.ImGui_DragFloat3(
        @ptrCast(name),
        @ptrCast(values),
    );
}

pub fn dragFloat3Ex(
    name: [:0]const u8,
    values: [*]f32,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    const min = blk: {
        if (vmin != null) break :blk vmin.?;
        break :blk std.math.floatMin(f32);
    };
    const max = blk: {
        if (vmax != null) break :blk vmax.?;
        break :blk std.math.floatMax(f32);
    };

    return ig.ImGui_DragFloat3Ex(
        @ptrCast(name),
        @ptrCast(values),
        speed,
        max,
        min,
        null,
        0,
    );
}

pub fn dragFloat4(
    name: [:0]const u8,
    values: [*]f32,
) bool {
    return ig.ImGui_DragFloat4(
        @ptrCast(name),
        @ptrCast(values),
    );
}

pub fn dragFloat4Ex(
    name: [:0]const u8,
    values: [*]f32,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    const min = blk: {
        if (vmin != null) break :blk vmin.?;
        break :blk std.math.floatMin(f32);
    };
    const max = blk: {
        if (vmax != null) break :blk vmax.?;
        break :blk std.math.floatMax(f32);
    };

    return ig.ImGui_DragFloat4Ex(
        @ptrCast(name),
        @ptrCast(values),
        speed,
        max,
        min,
        null,
        0,
    );
}

pub fn dragVec2(
    name: [:0]const u8,
    v: *Vec2,
) bool {
    return dragFloat2(name, @ptrCast(v));
}

pub fn dragVec2Ex(
    name: [:0]const u8,
    v: *Vec2,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    return dragFloat2Ex(
        name,
        @ptrCast(v),
        speed,
        vmin,
        vmax,
    );
}

pub fn dragVec3(
    name: [:0]const u8,
    v: *Vec3,
) bool {
    return dragFloat3(name, @ptrCast(v));
}

pub fn dragVec3Ex(
    name: [:0]const u8,
    v: *Vec3,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    return dragFloat3Ex(
        name,
        @ptrCast(v),
        speed,
        vmin,
        vmax,
    );
}

pub fn dragVec4(
    name: [:0]const u8,
    v: *Vec4,
) bool {
    return dragFloat4(name, @ptrCast(v));
}

pub fn dragVec4Ex(
    name: [:0]const u8,
    v: *Vec4,
    speed: f32,
    vmin: ?f32,
    vmax: ?f32,
) bool {
    return dragFloat4Ex(
        name,
        @ptrCast(v),
        speed,
        vmin,
        vmax,
    );
}

pub fn checkBox(name: [:0]const u8, b: *bool) bool {
    return ig.ImGui_Checkbox(@ptrCast(name), @ptrCast(b));
}

pub fn color3(name: [:0]const u8, c: *Color) bool {
    var v = c.clampedVec3();
    const res = ig.ImGui_ColorEdit3(@ptrCast(name), @ptrCast(&v), 0);
    c.* = Color.fromVec3(v);
    return res;
}

pub fn color4(name: [:0]const u8, c: *Color) bool {
    var v = c.clampedVec4();
    const res = ig.ImGui_ColorEdit4(@ptrCast(name), @ptrCast(&v), 0);
    c.* = Color.fromVec4(v);
    return res;
}

/// only bases the return value on position
pub fn transform(name: [:0]const u8, tf: *Transform) bool {
    var n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " position" },
        0,
    ) catch unreachable;
    const res = dragVec3Ex(n1, &tf.position, 0.1, null, null);
    state.allocator.free(n1);

    n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " scale" },
        0,
    ) catch unreachable;
    _ = dragVec3Ex(n1, &tf.scale, 0.1, null, null);
    state.allocator.free(n1);

    n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " rotation" },
        0,
    ) catch unreachable;
    _ = dragVec3Ex(n1, &tf.rotation, 0.1, null, null);
    state.allocator.free(n1);

    return res;
}

/// return value is based on whether color changed
pub fn material(name: [:0]const u8, mat: *Material) bool {
    var n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " color" },
        0,
    ) catch unreachable;
    const res = color3(n1, &mat.color);
    state.allocator.free(n1);

    n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " shininess" },
        0,
    ) catch unreachable;
    _ = dragFloat(n1, &mat.shininess);
    state.allocator.free(n1);

    return res;
}

pub fn renderItem(name: [:0]const u8, ri: *RenderItem) bool {
    const res = material(name, &ri.material);
    const n1 = std.mem.concatWithSentinel(
        state.allocator,
        u8,
        &.{ name, " hidden" },
        0,
    ) catch unreachable;
    _ = checkBox(n1, &ri.hidden);
    state.allocator.free(n1);

    return res;
}

pub fn spacing() void {
    ig.ImGui_Spacing();
}

/// returns result of transform
pub fn actor(name: [:0]const u8, actr: *Actor) bool {
    const res = transform(name, &actr.transform);
    _ = renderItem(name, &actr.render_item);
    return res;
}

// TODO: lights
