#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 1, local_size_z = 1) in;

layout (binding = 0, rgba32f) uniform image2D output_positions;

uint hash(uint x) {
    x += (x << 10u);
    x ^= (x >>  6u);
    x += (x <<  3u);
    x ^= (x >> 11u);
    x += (x << 15u);
    return x;
}

float rand(vec2 co) {
    uint seed = hash(uint(co.x) ^ uint(co.y));
    return fract(sin(float(seed)) * 43758.5453123);
}

void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);

    // Generate random position for a cube
    vec3 random_position = vec3(rand(gl_GlobalInvocationID.xy), rand(gl_GlobalInvocationID.xy * 2.0), rand(gl_GlobalInvocationID.xy * 3.0));

    // Store the random position in the output buffer
    imageStore(output_positions, pixel_coords, vec4(random_position, 1.0));
}
