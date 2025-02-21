#version 410 core

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec3 a_normal;

out vec3 normal;
out vec3 frag_pos; // fragment position

uniform mat4 model; // converts vectors to world_space
uniform mat3 inverse_model;
uniform mat4 projection;
uniform mat4 view;

uniform mat4 rotation;

void main() {
    vec4 pos =  vec4(a_position, 1.0);
    if (a_position.y > 0.0) {
        pos = rotation * pos;
    }
    gl_Position = projection * view * model * pos;
    frag_pos = vec3(model * pos);
    normal = normalize(inverse_model * a_normal);
}

