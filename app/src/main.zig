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
const Allocator = std.mem.Allocator;

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
var grass: *Actor = undefined;
var grass_shader: Shader = undefined;
var grass_model: Model = undefined;

var wind_direction = Vec3.init(1.0, 0.0, 0.0);

fn init() anyerror!void {
    allocator = engine.allocator();

    const scene = engine.scene();

    const light = scene.createPointLight("light");
    light.position.y = 8.5;

    ground = scene.createActor("ground");
    ground.render_item.loadModelData(renderer.cubeModel());
    ground.transform = .{
        .position = Vec3.init(0, -1.3, 0),
        .scale = Vec3.init(14.3, 1.0, 13.3),
    };

    grass = scene.createActor("grass");
    grass_model = Model.init(allocator, fs.modelPath("grass.glb"));
    grass.render_item.loadModelData(&grass_model);
    grass.render_item.material.color = Color.init(85, 171, 48);

    grass_shader = Shader.init(
        allocator,
        "shaders/grass.vert",
        fs.shaderPath("light_mesh.frag"),
    ) catch unreachable;
    engine.addShader(&grass_shader);
    grass.render_item.material.shader = &grass_shader;

    camera = engine.camera();
    camera.transform.position.z = 2;
}

var rand_lean: f32 = 1.0;
var height: f32 = 0.4;

fn setGrassUniforms() void {
    grass_shader.use();
    grass_shader.setMat3(
        "inverse_model",
        &grass
            .transform
            .mat4()
            .inverse()
            .transpose()
            .toMat3(),
    );

    const curve_amount: f32 = rand_lean * height;
    const grass_rot = Mat4.identity.rotateX(
        engine.math.toDegrees(curve_amount),
    );
    grass_shader.setMat4("rotation", &grass_rot);

    renderer.sendLightData(&grass_shader);
}

fn update() anyerror!void {
    setGrassUniforms();

    if (engine.cursorEnabled()) {
        ig.begin("user");
        defer ig.end();

        _ = ig.actor("ground", ground);
        _ = ig.actor("grass", grass);
        const scene = engine.scene();
        _ = ig.dragVec3Ex(
            "light pos",
            &scene.point_lights.get("light").?.position,
            0.01,
            null,
            null,
        );
        _ = ig.dragFloatEx(
            "rand lean",
            &rand_lean,
            0.01,
            null,
            null,
        );
        _ = ig.dragFloatEx(
            "height",
            &height,
            0.01,
            null,
            null,
        );
    }
}

fn deinit() void {
    grass_model.deinit();
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

test {
    std.testing.refAllDecls(@This());
}
