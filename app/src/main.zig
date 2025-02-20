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

var shader: Shader = undefined;
var camera: *Camera = undefined;
var actor: *Actor = undefined;
var monkey: Model = undefined;
var allocator: Allocator = undefined;
var ground: *Actor = undefined;
var grass: *Actor = undefined;
var grass_model: Model = undefined;

fn init() anyerror!void {
    allocator = engine.allocator();
    shader = try Shader.init(
        engine.allocator(),
        fs.shaderPath("rect.vert"),
        fs.shaderPath("rect.frag"),
    );
    engine.addShader(&shader);

    const scene = engine.scene();
    actor = scene.createActor("Monkey");
    actor.transform = Transform{};
    // const mesh = actor.render_item.createMesh();
    monkey = Model.init(allocator, fs.modelPath("monkey.glb"));
    actor.render_item.loadModelData(&monkey);

    const light = scene.createPointLight("light");
    light.position.y = 5.0;

    actor.render_item.material.createDiffuseTexture(
        fs.texturePath("water_normal.png"),
    );

    ground = scene.createActor("ground");
    ground.render_item.loadModelData(renderer.cubeModel());
    ground.transform = .{
        .position = Vec3.init(0, -2.6, 0),
        .scale = Vec3.init(14.3, 1.0, 13.3),
    };

    grass = scene.createActor("grass");

    grass_model = Model.init(allocator, fs.modelPath("grass.glb"));
    grass.render_item.loadModelData(&grass_model);

    // actor.render_item.material.shader = &shader;

    camera = engine.camera();
    camera.transform.position.z = 2;
    utils.logVec3("camera front", camera.front);
    utils.logVec3("camera rotation", camera.transform.rotation);
}

fn update() anyerror!void {
    debug.checkGlError();

    if (engine.cursorEnabled()) {
        ig.begin("user");
        defer ig.end();

        _ = ig.actor("monkey", actor);
        _ = ig.actor("ground", ground);
        _ = ig.actor("grass", grass);
    }

    if (input.mouseButtonClicked(.left)) {
        actor.render_item.material.color = Color.init(0, 255, 0);
    } else if (input.mouseButtonClicked(.right)) {
        actor.render_item.material.color = Color.from(255);
    }
}

fn deinit() void {
    grass_model.deinit();
    monkey.deinit();
}

pub fn main() !void {
    try engine.init(&.{
        .width = 1280,
        .height = 720,
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
