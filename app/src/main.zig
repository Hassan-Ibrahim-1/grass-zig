const std = @import("std");
const engine = @import("engine");
const gl = engine.gl;
const glfw = engine.glfw;
const debug = engine.debug;
const log = debug.log;
const utils = engine.utils;
const Shader = engine.Shader;
const ApplicationError = engine.ApplicationError;
const Vec3 = engine.math.Vec3;
const Vec2 = engine.math.Vec2;
const Mat4 = engine.math.Mat4;
const fs = engine.fs;
const Transform = engine.Transform;
const Camera = engine.Camera;
const VertexBuffer = engine.VertexBuffer;
const Color = engine.Color;
const Vertex = engine.Vertex;
const input = engine.input;
const Mesh = engine.Mesh;
const renderer = engine.renderer;
const Texture = engine.Texture;
const Actor = engine.Actor;
const Model = engine.Model;
const ig = engine.ig;
const math = engine.math;
const Allocator = std.mem.Allocator;

const ArrayList = std.ArrayList;

const vertices = [_]Vertex{
    Vertex.init(Vec3.init(0.5, 0.5, 0.0), Vec3.zero, Vec2.fromValue(1)),
    Vertex.init(Vec3.init(0.5, -0.5, 0.0), Vec3.zero, Vec2.init(1.0, 0.0)),
    Vertex.init(Vec3.init(-0.5, -0.5, 0.0), Vec3.zero, Vec2.zero),
    Vertex.init(Vec3.init(-0.5, 0.5, 0.0), Vec3.zero, Vec2.init(0.0, 1.0)),
};

const indices = [_]u32{
    0, 1, 3,
    1, 2, 3,
};

var camera: *Camera = undefined;
var allocator: Allocator = undefined;
var ground: *Actor = undefined;
var grass_shader: Shader = undefined;
var grass_model: Model = undefined;

var grass_blades: ArrayList(GrassBlade) = undefined;

var wind_direction = Vec3.init(1.0, 0.0, 0.0);

var rand: std.Random.Xoshiro256 = undefined;
var scene: *engine.Scene = undefined;

fn init() anyerror!void {
    allocator = engine.allocator();

    scene = engine.scene();

    const light = scene.createPointLight("light");
    light.position.y = 8.5;

    ground = scene.createActor("ground");
    ground.render_item.loadModelData(renderer.cubeModel());
    ground.transform = .{
        .position = Vec3.init(0, -1.3, 0),
        .scale = Vec3.init(14.3, 1.0, 13.3),
    };

    rand = math.rand;

    grass_blades = ArrayList(GrassBlade).init(allocator);
    grass_model = Model.init(allocator, fs.modelPath("grass.glb"));
    generateGrass(&.{
        .x = -4,
        .width = 6,
        .y = -4,
        .height = 6,
    });
    // grass.render_item.loadModelData(&grass_model);
    // grass.render_item.material.color = Color.init(85, 171, 48);

    grass_shader = Shader.init(
        allocator,
        "shaders/grass.vert",
        "shaders/grass.frag",
    ) catch unreachable;
    engine.addShader(&grass_shader);
    // grass.render_item.material.shader = &grass_shader;

    camera = engine.camera();
    camera.transform.position.z = 2;
}

fn update() anyerror!void {
    renderGrass();

    if (engine.cursorEnabled()) {
        ig.begin("user");
        defer ig.end();

        _ = ig.actor("ground", ground);
        _ = ig.dragVec3Ex(
            "light pos",
            &scene.point_lights.get("light").?.position,
            0.01,
            null,
            null,
        );

        ig.fpsCounter();
    }
}

fn deinit() void {
    grass_model.deinit();
    grass_blades.deinit();
}

pub fn main() !void {
    try engine.init(&.{
        .width = 1920,
        .height = 1080,
        .name = "App",
    });
    defer engine.deinit();

    engine.run(&.{
        .init = init,
        .update = update,
        .deinit = deinit,
    });

    log.info("TERMINATED", .{});
}

const GrassBlade = struct {
    // height is transform.scale.y
    transform: Transform,
    rand_lean: f32,
};

const Bounds = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

fn renderGrass() void {
    renderer.sendLightData(&grass_shader);
    for (grass_blades.items) |*blade| {
        const model = blade.transform.mat4();
        grass_shader.setMat3(
            "inverse_model",
            &model
                .inverse()
                .transpose()
                .toMat3(),
        );

        const curve_amount: f32 = blade.rand_lean * blade.transform.scale.y;
        const grass_rot = Mat4.identity.rotateX(
            engine.math.toDegrees(curve_amount),
        );
        grass_shader.setMat4("rotation", &grass_rot);
        grass_shader.setMat4("model", &model);
        const grass_color_max = Color.init(83, 179, 14).clampedVec3();
        const grass_color_min = Color.init(178, 212, 44).clampedVec3();
        const color = Vec3.lerp(
            grass_color_max,
            grass_color_min,
            blade.transform.scale.y,
        );
        grass_shader.setVec3("material.color", color);
        renderer.renderMesh(&grass_model.meshes.items[0]);
    }
}

fn generateGrass(bounds: *const Bounds) void {
    const count = 4000;
    for (0..count) |_| {
        createBlade(bounds);
    }
}

fn createBlade(bounds: *const Bounds) void {
    grass_blades.append(.{
        .transform = .{
            .position = randInBounds(bounds),
            .scale = Vec3.init(1, math.randomF32(0.5, 1.0), 1),
            .rotation = Vec3.init(0, math.randomF32(-45, 45), 0),
        },
        .rand_lean = math.randomF32(0.33, 0.36),
    }) catch unreachable;
    // rand lean values:
    // 0.39 - 0.44 with z
    // 0.33 - 3.36 without z
}

fn randInBounds(bounds: *const Bounds) Vec3 {
    const point = Vec2.init(
        math.randomF32(bounds.x, bounds.x + bounds.width),
        math.randomF32(bounds.y, bounds.y + bounds.height),
    );
    const normalizedX = 2.0 * (point.x / 1280) - 1.0;
    const normalizedY = 2.0 * (point.y / 720) - 1.0;
    return Vec3.init(normalizedX, 0, normalizedY);
}

test {
    std.testing.refAllDecls(@This());
}
