shader_type canvas_item;

uniform sampler2D occlusion_tex : repeat_disable, filter_nearest;

uniform float visible_threshold = 0.05;
uniform float hidden_threshold  = 0.25;
uniform vec4 silhouette_color : source_color = vec4(0.0, 1.0, 0.0, 0.6);

void fragment() {
    vec4 sprite_color = texture(TEXTURE, UV);

    if (sprite_color.a <= 0.01) {
        discard;
    }

    vec4 occ_color = texture(occlusion_tex, SCREEN_UV);
    float diff = length(sprite_color.rgb - occ_color.rgb);

    bool definitely_visible = (diff < visible_threshold) || (occ_color.a < 0.1);
    bool definitely_hidden  = (diff > hidden_threshold)  && (occ_color.a > 0.5);

    if (definitely_visible) {
        COLOR = sprite_color;
    } else if (definitely_hidden) {
        COLOR = vec4(silhouette_color.rgb, silhouette_color.a * sprite_color.a);
    } else {
        COLOR = sprite_color;
    }
}
