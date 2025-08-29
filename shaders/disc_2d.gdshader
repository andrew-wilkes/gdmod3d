shader_type canvas_item;

uniform float r1;
uniform float smoothing = 0.1;
uniform vec3 color : source_color =  vec3(.9);
uniform float highlight;

vec4 circle(vec2 uv, float rad1, float rad2, float edge_thickness) {
	float d = length(vec2(rad2) - uv);
	float brightness = step(rad1, d) * 0.2 + 0.8;
	vec3 col = color * brightness + vec3(highlight);
	return vec4(col, 1.0 - smoothstep(rad2 - edge_thickness, rad2, d));
}

void fragment() {
	COLOR = circle(UV, r1, 0.5, smoothing);
}
