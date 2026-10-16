shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 0.8);
uniform vec2 flow_direction = vec2(0.0, -1.0);
uniform float flow_speed = 0.5;
uniform sampler2D noise_texture : hint_default_white;

void fragment() {
    // Scroll UVs along the river curve length
    vec2 uv = UV + flow_direction * (TIME * flow_speed);
    float noise = texture(noise_texture, uv).r;

    ALBEDO = water_color.rgb + vec3(noise * 0.15);
    ALPHA = water_color.a;
    METALLIC = 0.1;
    ROUGHNESS = 0.05;
}