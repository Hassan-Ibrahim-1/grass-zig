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

fn ImVec4(r: f32, g: f32, b: f32, a: f32) ig.ImVec4 {
    return .{
        .x = r,
        .y = g,
        .z = b,
        .w = a,
    };
}

fn ImVec2(r: f32, g: f32) ig.ImVec2 {
    return .{
        .x = r,
        .y = g,
    };
}

pub fn setMaterialYouTheme() void {
    const style = ig.ImGui_GetStyle();
    var colors = style.*.Colors;

    // Base colors inspired by Material You (dark mode)
    colors[ig.ImGuiCol_Text] = ImVec4(0.93, 0.93, 0.94, 1.00);
    colors[ig.ImGuiCol_TextDisabled] = ImVec4(0.50, 0.50, 0.50, 1.00);
    colors[ig.ImGuiCol_WindowBg] = ImVec4(0.12, 0.12, 0.12, 1.00);
    colors[ig.ImGuiCol_ChildBg] = ImVec4(0.12, 0.12, 0.12, 1.00);
    colors[ig.ImGuiCol_PopupBg] = ImVec4(0.15, 0.15, 0.15, 1.00);
    colors[ig.ImGuiCol_Border] = ImVec4(0.25, 0.25, 0.28, 1.00);
    colors[ig.ImGuiCol_BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[ig.ImGuiCol_FrameBg] = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[ig.ImGuiCol_FrameBgHovered] = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[ig.ImGuiCol_FrameBgActive] = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[ig.ImGuiCol_TitleBg] = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[ig.ImGuiCol_TitleBgActive] = ImVec4(0.16, 0.16, 0.16, 1.00);
    colors[ig.ImGuiCol_TitleBgCollapsed] = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[ig.ImGuiCol_MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[ig.ImGuiCol_ScrollbarBg] = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[ig.ImGuiCol_ScrollbarGrab] = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[ig.ImGuiCol_ScrollbarGrabHovered] = ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[ig.ImGuiCol_ScrollbarGrabActive] = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[ig.ImGuiCol_CheckMark] = ImVec4(0.45, 0.76, 0.29, 1.00);
    colors[ig.ImGuiCol_SliderGrab] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_SliderGrabActive] = ImVec4(0.29, 0.66, 0.91, 1.00);
    colors[ig.ImGuiCol_Button] = ImVec4(0.18, 0.47, 0.91, 1.00);
    colors[ig.ImGuiCol_ButtonHovered] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_ButtonActive] = ImVec4(0.22, 0.52, 0.91, 1.00);
    colors[ig.ImGuiCol_Header] = ImVec4(0.18, 0.47, 0.91, 1.00);
    colors[ig.ImGuiCol_HeaderHovered] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_HeaderActive] = ImVec4(0.29, 0.66, 0.91, 1.00);
    colors[ig.ImGuiCol_Separator] = ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[ig.ImGuiCol_SeparatorHovered] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_SeparatorActive] = ImVec4(0.29, 0.66, 0.91, 1.00);
    colors[ig.ImGuiCol_ResizeGrip] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_ResizeGripHovered] = ImVec4(0.29, 0.66, 0.91, 1.00);
    colors[ig.ImGuiCol_ResizeGripActive] = ImVec4(0.29, 0.70, 0.91, 1.00);
    colors[ig.ImGuiCol_Tab] = ImVec4(0.18, 0.18, 0.18, 1.00);
    colors[ig.ImGuiCol_TabHovered] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_TabActive] = ImVec4(0.18, 0.47, 0.91, 1.00);
    colors[ig.ImGuiCol_TabUnfocused] = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[ig.ImGuiCol_TabUnfocusedActive] = ImVec4(0.18, 0.47, 0.91, 1.00);
    colors[ig.ImGuiCol_PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[ig.ImGuiCol_PlotLinesHovered] = ImVec4(0.29, 0.66, 0.91, 1.00);
    colors[ig.ImGuiCol_PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[ig.ImGuiCol_PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[ig.ImGuiCol_TableHeaderBg] = ImVec4(0.19, 0.19, 0.19, 1.00);
    colors[ig.ImGuiCol_TableBorderStrong] = ImVec4(0.31, 0.31, 0.35, 1.00);
    colors[ig.ImGuiCol_TableBorderLight] = ImVec4(0.23, 0.23, 0.25, 1.00);
    colors[ig.ImGuiCol_TableRowBg] = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[ig.ImGuiCol_TableRowBgAlt] = ImVec4(1.00, 1.00, 1.00, 0.06);
    colors[ig.ImGuiCol_TextSelectedBg] = ImVec4(0.29, 0.62, 0.91, 0.35);
    colors[ig.ImGuiCol_DragDropTarget] = ImVec4(0.29, 0.62, 0.91, 0.90);
    colors[ig.ImGuiCol_NavHighlight] = ImVec4(0.29, 0.62, 0.91, 1.00);
    colors[ig.ImGuiCol_NavWindowingHighlight] = ImVec4(1.00, 1.00, 1.00, 0.70);
    colors[ig.ImGuiCol_NavWindowingDimBg] = ImVec4(0.80, 0.80, 0.80, 0.20);
    colors[ig.ImGuiCol_ModalWindowDimBg] = ImVec4(0.80, 0.80, 0.80, 0.35);

    // Style adjustments
    style.*.WindowRounding = 8.0;
    style.*.FrameRounding = 4.0;
    style.*.ScrollbarRounding = 6.0;
    style.*.GrabRounding = 4.0;
    style.*.ChildRounding = 4.0;

    style.*.WindowTitleAlign = ImVec2(0.50, 0.50);
    style.*.WindowPadding = ImVec2(10.0, 10.0);
    style.*.FramePadding = ImVec2(8.0, 4.0);
    style.*.ItemSpacing = ImVec2(8.0, 8.0);
    style.*.ItemInnerSpacing = ImVec2(8.0, 6.0);
    style.*.IndentSpacing = 22.0;

    style.*.ScrollbarSize = 16.0;
    style.*.GrabMinSize = 10.0;

    style.*.AntiAliasedLines = true;
    style.*.AntiAliasedFill = true;
}
