shader_type canvas_item;

uniform float scale = 1.0;
uniform float dash_density = 32.0;
uniform float thickness = 0.08;

void fragment() {
	COLOR.a = 0.0;
	vec2 uv = (UV * 2.0) - vec2(1.0);
	float r = length(uv);
	float dr = (1.0 - r) * abs(scale);

	if (r < 1.0) {
		float dd = 1.0 / dash_density;
		float dash = asin(uv.y/ r);
		if (abs(uv.y) > 0.5) {
			dash = asin(uv.x/ r);
		}
		if (mod(dash/PI, dd) < dd / 2.0)
		COLOR = vec4(1.0);
		if (dr > thickness) {
			COLOR = vec4(0.35);
		}
	}
}