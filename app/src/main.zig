const std = @import("std");
const engine = @import("engine");
const gl = engine.gl;
const glfw = engine.glfw;
const debug = engine.debug;
const log = debug.log;
const utils = engine.utils;
const Shader = engine.Shader;
const Vec3 = math.Vec3;
const Vec2 = math.Vec2;
const Vec4 = math.Vec4;
const Mat4 = engine.math.Mat4;
const fs = engine.fs;
const Transform = engine.Transform;
const Camera = engine.Camera;
const VertexBuffer = engine.VertexBuffer;
const Color = engine.Color;
const Vertex = engine.Vertex;
const Mesh = engine.Mesh;
const renderer = engine.renderer;
const Texture = engine.Texture;
const Actor = engine.Actor;
const Model = engine.Model;
const ig = engine.ig;
const math = engine.math;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Bounds = math.Bounds;

const GrassData = struct {
    count: usize = 100_000,

    model: Model = undefined,
    // for instancing
    instance_vbo: c_uint = 0,
    blades: ArrayList(GrassBlade) = undefined,
    shader: Shader = undefined,
    /// contain the following matrices in the specified order
    /// model, inverse_model, rotation, color
    gpu_data: ArrayList(Vec4) = undefined,
};

var grass_data = GrassData{};

var camera: *Camera = undefined;
var allocator: Allocator = undefined;
var ground: *Actor = undefined;

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

    grass_data.blades = ArrayList(GrassBlade).init(allocator);
    grass_data.gpu_data = ArrayList(Vec4).init(allocator);
    grass_data.model = Model.init(allocator, fs.modelPath("grass.glb"));

    // generateGrass(&.{
    //     .x = -4,
    //     .width = 6,
    //     .y = -4,
    //     .height = 6,
    // });
    generateGrass(
        &Bounds.fromTransform(&ground.transform),
    );
    log.info("created {} blades of grass", .{grass_data.blades.items.len});
    sendGrassData();
    createGrassDrawCommand();
    // grass.render_item.loadModelData(&grass_data.model);
    // grass.render_item.material.color = Color.init(85, 171, 48);

    grass_data.shader = Shader.init(
        allocator,
        "shaders/grass.vert",
        "shaders/grass.frag",
    ) catch unreachable;
    engine.addShader(&grass_data.shader);
    // grass.render_item.material.shader = &grass_data.shader;

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
    grass_data.model.deinit();
    grass_data.blades.deinit();
    grass_data.gpu_data.deinit();
    gl.DeleteBuffers(1, @ptrCast(&grass_data.instance_vbo));
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

const GrassBlade = struct {
    height: f32,
    rand_lean: f32,
};

fn renderGrass() void {
    renderer.sendLightData(&grass_data.shader);
    // grass_data.shader.setFloat("time", engine.time());
    renderer.renderMesh(&grass_data.model.meshes.items[0]);

    // const grass_color_max = Color.init(83, 179, 14).clampedVec3();
    // const grass_color_min = Color.init(178, 212, 44).clampedVec3();
    // const color = Vec3.lerp(
    //     grass_color_max,
    //     grass_color_min,
    //     blade.height,
    // );
    // grass_data.shader.setVec3("material.color", color);
}

fn sendGrassData() void {
    const vb = &grass_data.model.meshes.items[0].vertex_buffer;
    vb.bind();
    defer vb.unbind();

    gl.GenBuffers(1, @ptrCast(&grass_data.instance_vbo));
    gl.BindBuffer(gl.ARRAY_BUFFER, grass_data.instance_vbo);
    engine.debug.checkGlError();
    engine.debug.checkGlError();

    log.info("before buffer data", .{});

    log.info("bytes: {}", .{
        @as(isize, @intCast(grass_data.gpu_data.items.len)) * @sizeOf(Vec4),
    });

    gl.BufferData(
        gl.ARRAY_BUFFER,
        @as(isize, @intCast(grass_data.gpu_data.items.len)) * @sizeOf(Vec4),
        @ptrCast(grass_data.gpu_data.items),
        gl.STATIC_DRAW,
    );

    log.info("after buffer data", .{});

    const v4s = @sizeOf(Vec4);
    const stride = 13 * v4s;

    // Model
    gl.EnableVertexAttribArray(2);
    gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, stride, 0);
    gl.EnableVertexAttribArray(3);
    gl.VertexAttribPointer(3, 4, gl.FLOAT, gl.FALSE, stride, 1 * v4s);
    gl.EnableVertexAttribArray(4);
    gl.VertexAttribPointer(4, 4, gl.FLOAT, gl.FALSE, stride, 2 * v4s);
    gl.EnableVertexAttribArray(5);
    gl.VertexAttribPointer(5, 4, gl.FLOAT, gl.FALSE, stride, 3 * v4s);

    gl.VertexAttribDivisor(2, 1);
    gl.VertexAttribDivisor(3, 1);
    gl.VertexAttribDivisor(4, 1);
    gl.VertexAttribDivisor(5, 1);

    // inverse
    gl.EnableVertexAttribArray(6);
    gl.VertexAttribPointer(6, 4, gl.FLOAT, gl.FALSE, stride, 4 * v4s);
    gl.EnableVertexAttribArray(7);
    gl.VertexAttribPointer(7, 4, gl.FLOAT, gl.FALSE, stride, 5 * v4s);
    gl.EnableVertexAttribArray(8);
    gl.VertexAttribPointer(8, 4, gl.FLOAT, gl.FALSE, stride, 6 * v4s);
    gl.EnableVertexAttribArray(9);
    gl.VertexAttribPointer(9, 4, gl.FLOAT, gl.FALSE, stride, 7 * v4s);

    gl.VertexAttribDivisor(6, 1);
    gl.VertexAttribDivisor(7, 1);
    gl.VertexAttribDivisor(8, 1);
    gl.VertexAttribDivisor(9, 1);

    // rotation
    gl.EnableVertexAttribArray(10);
    gl.VertexAttribPointer(10, 4, gl.FLOAT, gl.FALSE, stride, 8 * v4s);
    gl.EnableVertexAttribArray(11);
    gl.VertexAttribPointer(11, 4, gl.FLOAT, gl.FALSE, stride, 9 * v4s);
    gl.EnableVertexAttribArray(12);
    gl.VertexAttribPointer(12, 4, gl.FLOAT, gl.FALSE, stride, 10 * v4s);
    gl.EnableVertexAttribArray(13);
    gl.VertexAttribPointer(13, 4, gl.FLOAT, gl.FALSE, stride, 11 * v4s);

    gl.VertexAttribDivisor(10, 1);
    gl.VertexAttribDivisor(11, 1);
    gl.VertexAttribDivisor(12, 1);
    gl.VertexAttribDivisor(13, 1);

    gl.EnableVertexAttribArray(14);
    gl.VertexAttribPointer(14, 4, gl.FLOAT, gl.FALSE, stride, 12 * v4s);

    gl.VertexAttribDivisor(14, 1);
}

fn generateGrass(bounds: *const Bounds) void {
    for (0..grass_data.count) |_| {
        createBlade(bounds);
    }
}

fn createBlade(bounds: *const Bounds) void {
    const min_height = 0.5;
    const max_height = 1.0;
    const tf = Transform{
        .position = bounds.randF32(),
        .scale = Vec3.init(1, math.randomF32(min_height, max_height), 1),
        .rotation = Vec3.init(0, math.randomF32(-45, 45), 0),
    };
    const rand_lean = math.randomF32(0.33, 0.36);
    grass_data.blades.append(.{
        .height = tf.scale.y,
        .rand_lean = rand_lean,
    }) catch unreachable;

    const curve_amount: f32 = rand_lean * tf.scale.y;
    const grass_rot = Mat4.identity.rotateX(
        math.toDegrees(curve_amount),
    );

    // rand lean values:
    // 0.39 - 0.44 with z
    // 0.33 - 3.36 without z

    grass_data.gpu_data.appendSlice(
        &tf.mat4().asVec4(),
    ) catch unreachable;
    grass_data.gpu_data.appendSlice(
        &tf.mat4().inverse().transpose().asVec4(),
    ) catch unreachable;
    grass_data.gpu_data.appendSlice(
        &grass_rot.asVec4(),
    ) catch unreachable;
    // color
    // const grass_color_max = Color.init(83, 179, 14).clampedVec3();
    // const grass_color_min = Color.init(178, 212, 44).clampedVec3();
    const grass_color_max = Color.init(89, 245, 47).clampedVec3();
    const grass_color_min = Color.init(226, 255, 5).clampedVec3();
    const color = Vec3.lerp(
        grass_color_max,
        grass_color_min,
        tf.scale.y,
    );
    // const percent_height: f32 = (tf.scale.y - min_height) / max_height;
    grass_data.gpu_data.append(
        Vec4.init(
            color.x,
            color.y,
            color.z,
            tf.scale.y,
        ),
    ) catch unreachable;
}

fn createGrassDrawCommand() void {
    const mesh = &grass_data.model.meshes.items[0];
    const dc = &mesh.draw_command.?;
    dc.mode = .triangles;
    dc.type = .draw_elements_instanced;
    dc.vertex_count = mesh.vertex_buffer.indices.items.len;
    dc.instance_count = grass_data.count;
}

test {
    std.testing.refAllDecls(@This());
}
