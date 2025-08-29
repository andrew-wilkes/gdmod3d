shader_type spatial;

render_mode cull_disabled;

uniform float num_squares = 160.0;
uniform float interval = 5.0;
uniform float thin = 0.02;
uniform float thick = 0.01;
uniform float color_sat : hint_range(0, 1) = 0.1;
uniform float zoom = 1.0;

float getv(vec2 uv, float width, vec2 uv2) {
	// Don't mix grid with axis lines
	if (uv2.x < width) return 0.0;
	if (uv2.y < width) return 0.0;
	uv = fract(uv + vec2(width/2.0));
	vec2 v = step(vec2(width), uv);
	return 1.0 - v.x * v.y;
}

void fragment() {
	vec3 cam_norm = normalize(CAMERA_DIRECTION_WORLD);
	float tilt = min(0.9, length(cam_norm.xz));
	vec3 col = abs(cam_norm); // Need to consider custom axis colors
	vec2 uv = vec2(1.0) - SCREEN_UV * 2.0;
	vec2 uv2 = abs(vec2(1.0) - UV * 2.0) * num_squares / 2.0;
	vec2 uvthin = fract(uv2);
	vec2 uvthick = fract(uv2 / interval);
	// Compensate for reduced range of uv.y as tilt increases
	// Fade out as screen y increases
	// Note that negative alpha causes a black color
	float mult = 1.0 - clamp(pow(max(0.0, sign(cam_norm.y) * uv.y / (1.0 - tilt) * 0.4), 1.0), 0.0, 1.0);

	ALPHA = max(getv(uvthin, thin * num_squares * zoom / 160.0, uv2), getv(uvthick, thick * num_squares * zoom / 160.0, uv2)) * mult;
    ALBEDO = col * color_sat;
	NORMAL = vec3(0.0, 0.0, 1.0);
}
