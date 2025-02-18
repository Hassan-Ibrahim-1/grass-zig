pub const Window = @import("Window.zig");
pub const Shader = @import("Shader.zig");
pub const Transform = @import("Transform.zig");
pub const Camera = @import("Camera.zig");
pub const Color = @import("Color.zig");
pub const debug = @import("debug.zig");
pub const gl = @import("gl");
pub const math = @import("math.zig");
pub const utils = @import("utils.zig");
pub const cl = @import("clay");
pub const input = @import("input.zig");
pub const VertexBuffer = @import("VertexBuffer.zig");
pub const Vertex = @import("vertex.zig").Vertex;
const m = @import("mesh.zig");
pub const Mesh = m.Mesh;
pub const DrawCommand = m.DrawCommand;
pub const DrawCommandMode = m.DrawCommandMode;
pub const DrawCommandType = m.DrawCommandType;
pub const String = ArrayList(u8);
pub const Texture = @import("Texture.zig");
pub const Material = @import("Material.zig");
const light = @import("light.zig");
pub const PointLight = light.PointLight;
pub const SpotLight = light.SpotLight;
pub const DirLight = light.DirLight;
pub const renderer = @import("renderer.zig");
pub const Actor = @import("Actor.zig");
pub const RenderItem = @import("RenderItem.zig");
pub const Model = @import("Model.zig");
pub const Scene = @import("Scene.zig");
pub const Skybox = @import("Skybox.zig");

pub const glfw = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});
pub const ig = @cImport({
    @cInclude("dcimgui.h");
    @cInclude("backends/dcimgui_impl_glfw.h");
    @cInclude("backends/dcimgui_impl_opengl3.h");
});

const Fs = @import("Fs.zig");
/// use this to get access to engine resources
pub const fs = Fs.init(&.{
    .shader_dir = "../engine/shaders/",
    .font_dir = "../engine/fonts/",
    .texture_dir = "../engine/textures/",
    .model_dir = "../engine/models/",
});

const cl_renderer = @import("clay_renderer/renderer.zig");
const text = @import("text.zig");
const log = debug.log;
const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const std = @import("std");
const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator(.{});
const ArrayList = std.ArrayList;

pub const Application = struct {
    init: *const fn () anyerror!void,
    update: *const fn () anyerror!void,
    deinit: *const fn () void,
};

const EngineInitInfo = struct {
    width: u32,
    height: u32,
    name: [*:0]const u8,
};

const State = struct {
    gpa: GPA,
    allocator: Allocator,
    window: Window,
    app: *const Application,
    last_frame_time: f32 = 0.0,
    delta_time: f32 = 0.0,
    camera: Camera,
    wireframe_enabled: bool = false,
    shaders: ArrayList(*Shader),
    cursor_enabled: bool = false,
    scene: Scene,
    imio: *ig.ImGuiIO_t,
};

var state: State = undefined;

pub fn init(init_info: *const EngineInitInfo) !void {
    initAllocator();
    try initWindow(init_info);
    initCamera();
    state.shaders = ArrayList(*Shader).init(state.allocator);
    initScene();
    initImGui();

    input.init(state.allocator);
    try text.init(state.allocator);
    try cl_renderer.init(state.allocator);
    renderer.init(state.allocator);

    // for text rendering
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    gl.Enable(gl.DEPTH_TEST);
}

pub fn deinit() void {
    state.app.deinit();

    input.deinit();
    text.deinit();
    cl_renderer.deinit();
    renderer.deinit();
    state.shaders.deinit();
    deinitImGui();

    // deinit window after everything that requires opengl
    state.window.deinit();
    state.scene.deinit();
    glfw.glfwTerminate();
    std.debug.assert(state.gpa.deinit() == .ok);
}

pub const Size = struct {
    width: u32,
    height: u32,
};

pub fn windowSize() Size {
    return Size{
        .width = state.window.width,
        .height = state.window.height,
    };
}

pub fn window() *Window {
    return &state.window;
}

pub fn allocator() Allocator {
    return state.allocator;
}

pub fn deltaTime() f32 {
    return state.delta_time;
}

pub fn camera() *Camera {
    return &state.camera;
}

pub fn userShaders() *ArrayList(*Shader) {
    return &state.shaders;
}

pub fn scene() *Scene {
    return &state.scene;
}

pub fn wireframeEnabled() bool {
    return state.wireframe_enabled;
}

fn updateDeltaTime() void {
    const current_frame: f32 = @floatCast(glfw.glfwGetTime());
    state.delta_time = current_frame - state.last_frame_time;
    state.last_frame_time = current_frame;
}

fn startFrame() void {
    gl.ClearColor(0.1, 0.1, 0.1, 1);
    gl.Clear(gl.COLOR_BUFFER_BIT);
    gl.Clear(gl.DEPTH_BUFFER_BIT);
    updateDeltaTime();
    input.startFrame();
    cl_renderer.startFrame();
    renderer.startFrame();
    processInput();
    // createLayout();
}

fn endFrame() void {
    cl_renderer.endFrame();
    input.endFrame();

    state.window.swapBuffers();
}

/// added shaders will be reloaded when 'o' is pressed
/// they will be deinitalized at engine.deinit by renderer
pub fn addShader(shader: *Shader) void {
    state.shaders.append(shader) catch |err| {
        log.err("Failed to append shader: {s}", .{@errorName(err)});
        @panic("Allocation failed");
    };
}

fn update() void {
    startFrame();
    defer endFrame();

    state.app.update() catch @panic("user update failed");

    text.renderText(
        "the brown fox jumps\n over the lazy dog",
        Vec2.init(45.0, 100.0),
        1.0,
        Color.init(127, 121, 221),
    ) catch |err| {
        log.err("failed to render text: {s}", err);
    };

    renderer.render();

    imGuiUpdate();

    debug.checkGlError();
}

fn createLayout() void {
    const light_grey: cl.Color = .{ 224, 215, 210, 255 };
    const white: cl.Color = .{ 250, 250, 255, 255 };
    const red: cl.Color = .{ 168, 66, 28, 255 };
    const blue: cl.Color = .{ 0, 0, 255, 255 };
    _ = blue; // autofix
    cl.UI()(.{
        .id = cl.ElementId.ID("OuterContainer"),
        .layout = .{
            .direction = .left_to_right,
            .sizing = cl.Sizing.grow,
            .padding = cl.Padding.all(16),
            .child_gap = 16,
        },
        .background_color = white,
    })({
        cl.UI()(.{
            .id = cl.ElementId.ID("SideBar"),
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = cl.SizingAxis.grow, .w = cl.SizingAxis.fixed(300) },
                .padding = cl.Padding.all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 16,
            },
            .background_color = light_grey,
        })({
            cl.UI()(.{
                .id = cl.ElementId.ID("ProfilePictureOuter"),
                .layout = .{
                    .sizing = .{ .w = cl.SizingAxis.grow },
                    .padding = cl.Padding.all(16),
                    .child_alignment = .{ .x = .left, .y = .center },
                    .child_gap = 16,
                },
                .background_color = red,
            })({
                cl.UI()(.{
                    .id = cl.ElementId.ID("ProfilePicture"),
                    .layout = .{
                        .sizing = .{
                            .h = cl.SizingAxis.fixed(60),
                            .w = cl.SizingAxis.fixed(60),
                        },
                    },
                })({});
                cl.text("Clay - UI Library", .{ .font_size = 24, .color = light_grey });
            });

            for (0..5) |i| sidebarItemComponent(@intCast(i));
        });

        cl.UI()(.{
            .id = cl.ElementId.ID("MainContent"),
            .layout = .{ .sizing = cl.Sizing.grow },
            .background_color = light_grey,
        })({
            //...
        });
    });
}

fn sidebarItemComponent(index: u32) void {
    const sidebar_item_layout: cl.LayoutConfig = .{
        .sizing = .{
            .w = cl.SizingAxis.grow,
            .h = cl.SizingAxis.fixed(50),
        },
    };
    const orange: cl.Color = .{ 225, 138, 50, 255 };
    cl.UI()(.{
        .id = cl.ElementId.IDI("SidebarBlob", index),
        .layout = sidebar_item_layout,
        .background_color = orange,
    })({});
}

pub fn run(user_app: *const Application) void {
    state.app = user_app;
    state.app.init() catch @panic("Init failed");
    while (!state.window.shouldClose()) {
        update();
    }
}

fn initAllocator() void {
    state.gpa = GPA{};
    state.allocator = state.gpa.allocator();
}

fn glfwCallback(
    code: c_int,
    desc: [*c]const u8,
) callconv(.C) void {
    log.info("GLFW error: {} - {s}", .{ code, desc });
}

fn initWindow(init_info: *const EngineInitInfo) !void {
    if (glfw.glfwInit() == 0) return error.GlfwInitfailed;
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 1);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, 1);
    glfw.glfwSwapInterval(0);
    state.window = try Window.init(
        state.allocator,
        init_info.width,
        init_info.height,
        init_info.name,
    );

    _ = glfw.glfwSetErrorCallback(glfwCallback);
    state.window.enableCursor(false);
    // state.window.glfw_window.setInputModeCursor(.disabled);
}

fn initCamera() void {
    state.camera = Camera.init(Vec3.init(0, 1, 0));
}

fn initScene() void {
    state.scene = Scene.init(state.allocator);
    state.scene.loadDefaultSkybox();
}

fn initImGui() void {
    log.info("loading imgui", .{});
    _ = ig.CIMGUI_CHECKVERSION();
    _ = ig.ImGui_CreateContext(null);

    state.imio = @ptrCast(ig.ImGui_GetIO());
    state.imio.ConfigFlags = ig.ImGuiConfigFlags_NavEnableKeyboard;

    ig.ImGui_StyleColorsDark(null);

    _ = ig.cImGui_ImplGlfw_InitForOpenGL(@ptrCast(state.window.glfw_window), true);

    const glsl_version = "#version 410";
    _ = ig.cImGui_ImplOpenGL3_InitEx(glsl_version);
}

fn imGuiUpdate() void {
    if (state.cursor_enabled) {
        ig.cImGui_ImplOpenGL3_NewFrame();
        ig.cImGui_ImplGlfw_NewFrame();
        ig.ImGui_NewFrame();

        ig.ImGui_ShowDemoWindow(null);

        _ = ig.ImGui_Begin("hey", null, 0);
        ig.ImGui_End();

        ig.ImGui_Render();
        ig.cImGui_ImplOpenGL3_RenderDrawData(ig.ImGui_GetDrawData());
    }
}

fn deinitImGui() void {
    ig.cImGui_ImplOpenGL3_Shutdown();
    ig.cImGui_ImplGlfw_Shutdown();
    ig.ImGui_DestroyContext(null);
}

pub fn imGuiIo() *ig.ImGuiIO_t {
    return state.imio;
}

fn enableWireframe() void {
    if (state.wireframe_enabled) return;
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    state.wireframe_enabled = true;
}

fn disableWireframe() void {
    if (!state.wireframe_enabled) return;
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
    state.wireframe_enabled = false;
}

fn processInput() void {
    // TODO:: KEY DOWN BROKEN
    if (input.keyPressed(.one)) {
        // log.info("pressed one", .{});
        if (state.wireframe_enabled) {
            disableWireframe();
        } else {
            enableWireframe();
        }
    }
    if (input.keyPressed(.o)) {
        log.info("Reloading shaders", .{});
        text.getShader().reload() catch |err| {
            log.err(
                "Failed to reload shader: {s}",
                .{@errorName(err)},
            );
        };
        for (state.shaders.items) |shader| {
            shader.reload() catch |err| {
                log.err(
                    "Failed to reload shader: {s}",
                    .{@errorName(err)},
                );
            };
        }
    }
    if (input.keyPressed(.two)) {
        state.cursor_enabled = !state.cursor_enabled;
        if (!state.cursor_enabled) {
            state.window.enableCursor(false);
        } else {
            state.window.enableCursor(true);
        }
    }
}

pub fn cursorEnabled() bool {
    return state.cursor_enabled;
}

fn updateCursor() void {
    if (state.cursor_enabled) {}
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
