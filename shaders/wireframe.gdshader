shader_type spatial;

render_mode cull_disabled;

// COLOR.rgb is used to mark the corners
// COLOR.a is used to mark an edge for hiding
// UV2.xy is used to mark an edge for highlighting

uniform float quad_mode = 1.0; // Set to zero to show all triangles
uniform float vertex_mode = 1.0; // Set to zero to hide vertex selections
uniform float edge_mode = 1.0; // Set to zero to hide edges selections

uniform vec3 vertex_color : source_color = vec3(0.8, 0.5, 0.0);
uniform vec3 wire_color : source_color = vec3(1.0);
uniform vec3 highlight_color : source_color = vec3(0.0, 1.0, 0.0);
//uniform vec3 face_color : source_color = vec3(0.8); // Not used here

uniform float corner_size = 0.05;
uniform float wire_size = 0.02;

void fragment() {
	vec3 color = COLOR.rgb;
	float near_one = 0.95;

	float highlight = max(UV2.x, UV2.y);

	// Get radial distances from corners
	float corner_dist_1 = length(color.rg);
	float corner_dist_2 = length(color.rb);
	float corner_dist_3 = length(color.gb);
	float corner_dist = min(min(corner_dist_1, corner_dist_2), corner_dist_3);

	// Get distance from edge
	float edge_dist = min(color.r, min(color.g, color.b));

	// Set the colors
	vec3 vtx_color = mix(vertex_color, highlight_color, step(near_one, highlight));
	color = mix(wire_color, vtx_color, step(corner_dist, corner_size * vertex_mode));
	vec3 edge_color = mix(wire_color, highlight_color, step(near_one, highlight));
	ALBEDO = mix(color, edge_color, step(0.5, edge_mode));

	// Derive a constant width with range for the wires
	// Use ALPHA to show and fade out the edges of the wires
	float delta = (abs(dFdx(edge_dist)) + abs(dFdy(edge_dist))) * wire_size * 100.0;
	ALPHA = mix(0.0, smoothstep(edge_dist, edge_dist + delta, delta), mix(step(wire_size * quad_mode, COLOR.a), 1.0, step(corner_dist, wire_size)));
}
