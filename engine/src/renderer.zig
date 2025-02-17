const std = @import("std");
const gl = @import("gl");
const engine = @import("engine.zig");
const log = engine.debug.log;
const debug = engine.debug;
const Mesh = engine.Mesh;
const assert = debug.assert;
const Allocator = std.mem.Allocator;
const Actor = engine.Actor;
const Camera = engine.Camera;
const Shader = engine.Shader;
const Mat4 = math.Mat4;
const Material = engine.Material;
const fs = engine.fs;
const ArrayList = std.ArrayList;
const String = engine.String;
const math = engine.math;
const Mat3 = math.Mat3;
const Skybox = engine.Skybox;
const Model = engine.Model;

// When adding a shader
// add it to the Shaders struct
// then to initShaders

const Shaders = struct {
    basic_textured_mesh: Shader,
    basic_mesh: Shader,
    light_mesh: Shader,
    light_textured_mesh: Shader,
    skybox: Shader,
};

const State = struct {
    allocator: Allocator,
    shaders: Shaders,
    camera: *Camera,
    user_shaders: *ArrayList(*Shader),
    cube: Model,
};

var state: State = undefined;

pub fn init(allocator: Allocator) void {
    state.allocator = allocator;
    initShaders();
    state.camera = engine.camera();
    state.user_shaders = engine.userShaders();
    initModels();
}

pub fn deinit() void {
    deinitModels();
    deinitShaders();
}

pub fn initModels() void {
    state.cube = Model.init(
        state.allocator,
        fs.modelPath("cube.glb"),
    );
}

pub fn deinitModels() void {
    state.cube.deinit();
}

fn initShaders() void {
    state.shaders.basic_mesh = Shader.init(
        state.allocator,
        fs.shaderPath("basic_mesh.vert"),
        fs.shaderPath("basic_mesh.frag"),
    ) catch {
        @panic("failed to load shader");
    };
    engine.addShader(&state.shaders.basic_mesh);
    state.shaders.basic_textured_mesh = Shader.init(
        state.allocator,
        fs.shaderPath("basic_textured_mesh.vert"),
        fs.shaderPath("basic_textured_mesh.frag"),
    ) catch {
        @panic("failed to load shader");
    };
    engine.addShader(&state.shaders.basic_textured_mesh);

    state.shaders.light_mesh = Shader.init(
        state.allocator,
        fs.shaderPath("light_mesh.vert"),
        fs.shaderPath("light_mesh.frag"),
    ) catch {
        @panic("failed to load shader");
    };
    engine.addShader(&state.shaders.light_mesh);

    state.shaders.light_textured_mesh = Shader.init(
        state.allocator,
        fs.shaderPath("light_textured_mesh.vert"),
        fs.shaderPath("light_textured_mesh.frag"),
    ) catch {
        @panic("failed to load shader");
    };
    engine.addShader(&state.shaders.light_textured_mesh);

    state.shaders.skybox = Shader.init(
        state.allocator,
        fs.shaderPath("skybox.vert"),
        fs.shaderPath("skybox.frag"),
    ) catch {
        @panic("failed to load shader");
    };
    engine.addShader(&state.shaders.skybox);
}

pub fn deinitShaders() void {
    for (engine.userShaders().items) |shader| {
        shader.deinit();
    }
}

pub fn startFrame() void {}

pub fn render() void {
    const view = state.camera.getViewMatrix();
    const proj = state.camera.getPerspectiveMatrix();
    setCameraMatrices(&view, &proj);

    renderActors();

    if (!engine.scene().skybox_hidden) {
        renderSkybox(&engine.scene().skybox);
    }
}

pub fn endFrame() void {}

fn setCameraMatrices(view: *const Mat4, proj: *const Mat4) void {
    // all renderer shaders get added to user_shaders in initShaders
    for (state.user_shaders.items) |shader| {
        shader.use();
        shader.setMat4("view", view);
        shader.setMat4("projection", proj);
    }
}

fn renderActors() void {
    const scene = engine.scene();
    var iter = scene.actors.iterator();
    if (scene.hasLights()) {
        sendLightData(&state.shaders.light_mesh);
        // sendLightData(&state.shaders.light_textured_mesh);
    }
    while (iter.next()) |actor| {
        renderActor(actor.value_ptr.*);
    }
}

fn renderActor(actor: *const Actor) void {
    const render_item = &actor.render_item;
    const mat = &render_item.material;
    if (render_item.hidden) return;
    const model = actor.transform.mat4();
    const scene = engine.scene();
    var shader: *Shader = undefined;
    if (mat.shader) |s| {
        shader = s;
        shader.use();
    } else {
        if (scene.hasLights()) {
            if (mat.hasDiffuseTextures()) {
                shader = &state.shaders.light_textured_mesh;
                // calls shader.use
                sendLightData(shader);
                sendTextureData(mat, shader);
                shader.setMat3(
                    "inverse_model",
                    &model.inverse().transpose().toMat3(),
                );
                shader.setFloat("material.shininess", mat.shininess);
            } else {
                shader = &state.shaders.light_mesh;
                shader.use();
                shader.setMat3(
                    "inverse_model",
                    &model.inverse().transpose().toMat3(),
                );
                shader.setFloat("material.shininess", mat.shininess);
            }
        } else {
            if (mat.hasDiffuseTextures()) {
                shader = &state.shaders.basic_textured_mesh;
                sendTextureData(mat, shader);
            } else {
                shader = &state.shaders.basic_mesh;
                shader.use();
            }
        }
    }
    shader.setMat4("model", &model);
    shader.setVec3("material.color", mat.color.clampedVec3());
    for (render_item.meshes.items) |*mesh| {
        renderMesh(mesh);
    }
}

fn sendTextureData(mat: *const Material, shader: *Shader) void {
    shader.use();
    var i: usize = 0;
    while (i < mat.diffuseTextureCount()) : (i += 1) {
        mat.diffuse_textures.items[i].bindSlot(i);
        const str = std.fmt.allocPrintZ(
            state.allocator,
            "material.texture_diffuse{}",
            .{i + 1},
        ) catch unreachable;
        defer state.allocator.free(str);
        shader.setSampler(@ptrCast(str), i);
    }
    i = 0;
    while (i < mat.specularTextureCount()) : (i += 1) {
        mat.specular_textures.items[i].bindSlot(i);
        const str = std.fmt.allocPrintZ(
            state.allocator,
            "material.texture_specular{}",
            .{i + 1},
        ) catch unreachable;
        defer state.allocator.free(str);
        shader.setSampler(@ptrCast(str), i);
    }
}

fn sendLightData(shader: *Shader) void {
    const scene = engine.scene();
    shader.use();

    debug.checkGlError();
    shader.setVec3("view_pos", engine.camera().transform.position);
    shader.setInt("n_point_lights_used", @intCast(scene.pointLightCount()));
    shader.setInt("n_spot_lights_used", @intCast(scene.spotLightCount()));
    shader.setInt("n_dir_lights_used", @intCast(scene.dirLightCount()));

    var p_iter = scene.point_lights.iterator();
    var i: usize = 0;
    while (p_iter.next()) |light| : (i += 1) {
        const name = std.fmt.allocPrintZ(
            state.allocator,
            "point_lights[{}]",
            .{i},
        ) catch unreachable;
        defer state.allocator.free(name);
        light.value_ptr.*.sendToShader(state.allocator, name, shader);
    }

    var s_iter = scene.spot_lights.iterator();
    i = 0;
    while (s_iter.next()) |light| : (i += 1) {
        const name = std.fmt.allocPrintZ(
            state.allocator,
            "spot_lights[{}]",
            .{i},
        ) catch unreachable;
        defer state.allocator.free(name);
        light.value_ptr.*.sendToShader(state.allocator, name, shader);
    }

    var d_iter = scene.dir_lights.iterator();
    i = 0;
    while (d_iter.next()) |light| : (i += 1) {
        const name = std.fmt.allocPrintZ(
            state.allocator,
            "dir_lights[{}]",
            .{i},
        ) catch unreachable;
        defer state.allocator.free(name);
        light.value_ptr.*.sendToShader(state.allocator, name, shader);
    }
}

/// assumes shader is in use
pub fn renderMesh(mesh: *const Mesh) void {
    assert(mesh.buffersCreated(), "Mesh has no draw command", .{});
    const dc = mesh.draw_command.?;
    const mode: c_uint = @intCast(dc.mode.toInt());
    mesh.vertex_buffer.bind();
    defer mesh.vertex_buffer.unbind();
    switch (dc.type) {
        .draw_arrays => {
            gl.DrawArrays(mode, 0, @intCast(dc.vertex_count));
        },
        .draw_elements => {
            gl.DrawElements(mode, @intCast(dc.vertex_count), gl.UNSIGNED_INT, 0);
        },
        else => {
            log.err(
                "draw command type {s} not supported",
                .{@tagName(dc.type)},
            );
        },
    }
}

fn renderSkybox(skybox: *Skybox) void {
    assert(skybox.loaded(), "skybox not loaded", .{});

    if (engine.wireframeEnabled()) {
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
    }

    const shader = &state.shaders.skybox;
    shader.use();
    gl.ActiveTexture(gl.TEXTURE0);
    shader.setInt("skybox", 0);
    shader.setMat4(
        "view",
        &engine
            .camera()
            .getViewMatrix()
            .toMat3()
            .toMat4(),
    );
    gl.BindTexture(gl.TEXTURE_CUBE_MAP, skybox.handle);

    gl.DepthFunc(gl.LEQUAL);
    defer gl.DepthFunc(gl.LESS);

    const mesh = state.cube.meshes.items[0];
    renderMesh(&mesh);

    if (engine.wireframeEnabled()) {
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
    }
}
