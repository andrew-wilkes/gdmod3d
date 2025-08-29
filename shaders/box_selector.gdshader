shader_type canvas_item;

uniform vec2 scale = vec2(1.0);

void fragment() {
	COLOR.a = 0.0;
	float thickness = 0.04;
	float dx = min(UV.x, 1.0 - UV.x) * abs(scale.x);
	float dy = min(UV.y, 1.0 - UV.y) * abs(scale.y);
	float dist = min(dx, dy);
	if (dist < thickness) {
		if (mod(dx + dy, 0.4) < 0.2) {
			COLOR = vec4(1.0);
		}
	}
	if (dist > thickness) {
		COLOR = vec4(0.35);
	}
}
