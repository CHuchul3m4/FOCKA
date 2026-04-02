shader_type canvas_item;

uniform bool rainbow = false;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_scale : hint_range(0.0, 20.0) = 1.2;
uniform float frequency : hint_range(0.0, 2.0) = 0.5;
uniform float light_offset : hint_range(0.00001, 1.0) = 0.5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_scale;

    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;

    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;

    outline = clamp(outline, 0.0, 1.0);

    vec4 animated_line_color = vec4(
        light_offset + sin(2.0 * PI * frequency * TIME),
        light_offset + sin(2.0 * PI * frequency * TIME + radians(120.0)),
        light_offset + sin(2.0 * PI * frequency * TIME + radians(240.0)),
        alpha
    );

    vec4 base_color = texture(TEXTURE, UV);

    float mask = max(outline - base_color.a, 0.0);

    if (rainbow) {
        COLOR = mix(base_color, animated_line_color, mask);
    } else {
        COLOR = mix(base_color, line_color, mask);
    }
}