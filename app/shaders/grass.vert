#version 410 core

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec3 a_normal;

layout (location = 2) in mat4 a_model;
layout (location = 6) in mat4 a_inverse_model;
layout (location = 10) in mat4 a_rotation;
layout (location = 14) in vec4 a_color;

out vec3 normal;
out vec3 frag_pos; // fragment position

out vec3 color;
out float vertex_height;

uniform mat4 projection;
uniform mat4 view;
// uniform float time;

// float random2d(vec2 coord) {
//     return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
// }

void main() {
    vec4 pos =  vec4(a_position, 1.0);
    if (a_position.y > 0.0) {
        pos = a_rotation * pos;
    }
    // if (a_position.y > 0.2) {
    //     const float mult = 0.01;
    //     float rand = random2d(a_position.xy);
    //     float offset = mult * sin(time) - (a_position.x * 0.1 + rand * 0.1);
    //     // if (a_position.y == 1.0f) {
    //     //     offset = ((offset + 0.5) + (offset - 0.5));
    //     // }
    //     pos.x += offset * 0.7;
    // }

    gl_Position = projection * view * a_model * pos;
    frag_pos = vec3(a_model * pos);
    mat3 inverse_model = mat3(a_inverse_model);
    normal = normalize(inverse_model * a_normal);
    color = a_color.rgb;

    vertex_height = (a_position.y + 1) / 1.75;
}

