#version 410 core

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec3 a_normal;

layout (location = 2) in mat4 a_model;
layout (location = 7) in mat4 a_inverse_model;
layout (location = 11) in mat4 a_rotation;
layout (location = 15) in vec4 a_color;

out vec3 color;

out vec3 normal;
out vec3 frag_pos; // fragment position

uniform mat4 projection;
uniform mat4 view;

void main() {
    vec4 pos =  vec4(a_position, 1.0);
    if (a_position.y > 0.0) {
        pos = a_rotation * pos;
    }
    gl_Position = projection * view * a_model * pos;
    frag_pos = vec3(a_model * pos);
    mat3 inverse_model = mat3(a_inverse_model);
    normal = normalize(inverse_model * a_normal);
    color = a_color.rgb;
}

