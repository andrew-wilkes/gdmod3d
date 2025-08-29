shader_type spatial;
render_mode unshaded;

uniform vec3 mask_color = vec3(0.0, 1.0, 0.0); // Be able to hide an axis

void fragment() {
	// Point to the camera
	NORMAL = vec3(0.0, 0.0, 1.0);
	// Get color from vertex color
	ALBEDO = COLOR.rgb;

	ALPHA = step(0.1, distance(mask_color, ALBEDO));
}
