shader_type spatial;

render_mode cull_front;

uniform float vertex_mode = 1.0; // Set to zero to hide vertex selections
uniform float edge_mode = 1.0; // Set to zero to hide edges selections
uniform vec3 highlight_color : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 face_color : source_color = vec3(0.8);
uniform float corner_size = 0.02;

void fragment() {
	vec3 col = COLOR.rgb;

	// Get minimum distance to corners
	float rdist = length(col.rg);
	float gdist = length(vec2(col.g, 1.0 - col.r));
	float bdist = length(vec2(1.0 - col.g, col.r));
	float minc = min(min(rdist, gdist), bdist);
	float proximity = max(UV2.x, UV2.y);

	vec3 color = face_color;
	if (minc < corner_size * vertex_mode && proximity > 0.9) {
		color = highlight_color;
	}
	if (UV2.x * edge_mode > 0.99 || UV2.y * edge_mode > 0.99) {
		color = highlight_color;
	}
	if (FRONT_FACING) {
		discard;
	} else {
		ALBEDO = mix(color, highlight_color, proximity * (1.0 - edge_mode) * (1.0 - vertex_mode));
	}
}
