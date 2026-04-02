shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

uniform int blur_type = 0;
uniform int blur_amount = 16;
uniform float blur_radius = 1.0;
uniform vec2 blur_direction = vec2(1.0, 1.0);

// -------------------- XOR GAUSSIAN --------------------
vec4 texture_xorgaussian(sampler2D tex, vec2 uv, vec2 pixel_size, float blurriness, int iterations, int quality){
	float pi = 6.283185;
	
	vec2 radius = blurriness / (1.0 / pixel_size).xy;
	vec4 blurred_tex = texture(tex, uv);
	
	for(float d = 0.0; d < pi; d += pi / float(iterations)){
		for(float i = 1.0 / float(quality); i <= 1.0; i += 1.0 / float(quality)){
			vec2 directions = uv + vec2(cos(d), sin(d)) * radius * i;
			blurred_tex += texture(tex, directions);
		}
	}
	
	blurred_tex /= float(quality * iterations) + 1.0;
	return blurred_tex;
}

// -------------------- MONKS GAUSSIAN --------------------
vec4 texture_monksgaussian_multipass(sampler2D tex, vec2 uv, vec2 pixel_size, int iterations, vec2 direction){
	vec4 blurred_tex = vec4(0.0);
	vec2 resolution = 1.0 / pixel_size;
	
	for (int i = 0; i < iterations; i++){
		float size = float(iterations - i);
		
		vec2 off1 = vec2(1.3846153846) * (direction * size);
		vec2 off2 = vec2(3.2307692308) * (direction * size);

		blurred_tex += texture(tex, uv) * 0.2270270270;
		blurred_tex += texture(tex, uv + (off1 / resolution)) * 0.3162162162;
		blurred_tex += texture(tex, uv - (off1 / resolution)) * 0.3162162162;
		blurred_tex += texture(tex, uv + (off2 / resolution)) * 0.0702702703;
		blurred_tex += texture(tex, uv - (off2 / resolution)) * 0.0702702703;
	}
	
	blurred_tex /= float(iterations) + 1.0;
	return blurred_tex;
}

// -------------------- NODEV SINGLE --------------------
vec4 texture_nodevgaussian_singlepass(sampler2D tex, vec2 uv, vec2 pixel_size, float blurriness, float radius){
	float pi = 3.14159;
	float n = 0.0015;
	
	vec4 blurred_tex = vec4(0.0);
	float weight = 0.0;
	
	for (float i = -blurriness; i <= blurriness; i++){
		float d = i / pi;
		vec2 anchor = vec2(cos(d), sin(d)) * radius * i;
		vec2 directions = uv + pixel_size * anchor;
		
		blurred_tex += texture(tex, directions) * n;
		
		if (i <= 0.0) n += 0.0015;
		else n -= 0.0015;
		
		weight += n;
	}
	
	blurred_tex *= (1.0 / weight);
	return blurred_tex;
}

// -------------------- NODEV MULTI --------------------
vec4 texture_nodevgaussian_multipass(sampler2D tex, vec2 uv, vec2 pixel_size, float blurriness, vec2 direction){
	float n = 0.0015;
	
	vec4 blurred_tex = vec4(0.0);
	float weight = 0.0;
	
	for (float i = -blurriness; i <= blurriness; i++){
		vec2 directions = uv + pixel_size * (direction * i);
		
		blurred_tex += texture(tex, directions) * n;
		
		if (i <= 0.0) n += 0.0015;
		else n -= 0.0015;
		
		weight += n;
	}
	
	blurred_tex *= (1.0 / weight);
	return blurred_tex;
}

// -------------------- MAIN --------------------
void fragment(){
	vec2 uv = SCREEN_UV;

	if (blur_type == 0){
		COLOR = texture_xorgaussian(screen_texture, uv, SCREEN_PIXEL_SIZE, float(blur_amount), 16, 4);
	}
	else if (blur_type == 1){
		COLOR = texture_monksgaussian_multipass(screen_texture, uv, SCREEN_PIXEL_SIZE, blur_amount, blur_direction);
	}
	else if (blur_type == 2){
		COLOR = texture_nodevgaussian_singlepass(screen_texture, uv, SCREEN_PIXEL_SIZE, float(blur_amount), blur_radius);
	}
	else if (blur_type == 3){
		COLOR = texture_nodevgaussian_multipass(screen_texture, uv, SCREEN_PIXEL_SIZE, float(blur_amount), blur_direction);
	}
	else{
		COLOR = texture(screen_texture, uv);
	}
}