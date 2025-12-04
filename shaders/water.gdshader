//Water by DuoRift
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D distortion_noise : repeat_enable, filter_nearest;
uniform sampler2D fractals : repeat_enable, filter_nearest;

uniform vec2 direction = vec2(3.0, 2.0);
uniform vec4 water_color : source_color;
uniform vec4 fractal_color : source_color;

varying vec2 world_position;

uniform float scale : hint_range(1.0, 512.0, 0.5) = 64.0;
uniform float opacity : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float distortion_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float fractal_strength : hint_range(0.0, 1.0, 0.05) = 0.5;


void vertex() {
    // Calculate the World Position for use in the Fragment Shader
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


void fragment() {
    // Allow movement over time
    vec2 distort_uv = UV + vec2(10.0) * TIME;
    vec2 move_uv = UV + direction * TIME;

    // Set the distortion by world position, movement and scale
    vec4 noise1 = texture(distortion_noise, (world_position + distort_uv) * 0.005);
    vec4 noise2 = texture(distortion_noise, (world_position - distort_uv - 16.0) * 0.005);
    float depth = noise1.r * noise2.r;

    vec4 distortion = texture(SCREEN_TEXTURE, SCREEN_UV + distortion_strength / 50.0 * vec2(depth));

    // Add foam & fractals
    vec4 frac_up = texture(fractals, (world_position + depth * 3.0 * move_uv) * 1.0 / scale);
    vec4 frac_down = texture(fractals, (world_position + depth * 3.0 - move_uv * 16.0) * 1.0 / scale);

    vec4 fractal = (frac_up * 0.2 + frac_up * 0.2 + frac_down * 0.05) * fractal_strength;

    // set distortion, water color and fractals to base color
	vec4 base = COLOR;
	vec4 water = mix(distortion, water_color, opacity) + fractal;
	if (base.r >= 0.01) {COLOR = fractal_color + noise1.r * opacity * 2.0;}
	if (base.b >= 0.01) {COLOR = water;}
}
