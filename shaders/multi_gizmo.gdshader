shader_type canvas_item;

uniform float asize = 0.4;
uniform float ellipse_thickness = 0.2;
uniform float ellipse_alpha = 0.8;
uniform float smoothing = 0.02;
uniform float r1 = 0.18;
uniform float r2 = 0.75;
uniform vec4 ring_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform float ring_thickness = 0.05;
uniform float disc_radius = 0.59;
uniform vec4 disc_color : source_color = vec4(0.5);
uniform vec3 vx = vec3(1.0, 0.0, 0.0); // Vertex normal for x.
uniform vec3 vy = vec3(0.0, 1.0, 0.0);
uniform vec3 vz = vec3(0.0, 0.0, 1.0);
uniform vec4 colorx : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 colory : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 colorz : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float square_size = 0.15;
uniform float square_pos = 0.445; // Distance along normal
uniform float small_circle_radius = 0.1;
uniform float small_circle_pos = 0.9; // Distance along normal to middle of circle
uniform float line_width = 0.08;
uniform vec2 lx = vec2(0.16, 0.83);
uniform vec2 ly = vec2(0.16, 0.83);
uniform vec2 lz = vec2(0.16, 0.83);
uniform vec2 mouse_uv;
uniform float highlight_value = 0.2;
uniform bool show_x;
uniform bool show_y;
uniform bool show_z;
uniform bool hide_rear = true;

vec4 circle(vec2 uv, float rad1, float rad2, float feather, vec4 col, float highlight) {
	float thickness = rad2 - rad1;
	float d = length(uv);
	col.rgb += vec3(highlight);
	col.a *= (smoothstep(rad2 - thickness - feather, rad2 - thickness, d) - smoothstep(rad2 - feather, rad2, d));
	return col;
}

vec4 ellipse(vec2 uv, float a, float thickness, float feather, vec3 normal, vec4 col, float highlight) {
	col.rgb += vec3(highlight);
	float b = dot(vec3(0.0, 0.0, 1.0), vec3(normal.xy, abs(normal.z))); // Get a positive distance value
	float xylen = length(normal.xy); // Get the distance in the xy plane of the tip of the normal from the origin
	vec2 norm = vec2(1.0, 0.0); // The substitute value when x and y are zero where we cannot normalize the xy vector
	float solid = 1.0;
	if (xylen > 0.001) { // In this case, we are able to normalize the xy vector and rotate uv
		norm = normalize(normal.xy);
		if (!hide_rear) {
			// Display rotation line
			float h = dot(normalize(uv), normalize(vec2(mouse_uv.x, -mouse_uv.y))); // Distance of mouse from plane
			float d  = sqrt(1.0 - h * h) * length(uv); // Distance of mouse perpendicalar to uv.
			if (h > 0.0 && d < 0.02 && length(uv) > r1) {
				solid = 0.0;
			}
		}
		mat2 rm = mat2(vec2(-norm.y, norm.x), vec2(-norm.x, -norm.y));
		uv = rm * uv;
	}
	float r = (uv.x * uv.x + uv.y * uv.y / b / b) * a;
	col.a *= (smoothstep(r, r + feather, 1.0) - smoothstep(r - feather, r, 1.0 - thickness) * solid);
	col *= step(0.3, b) * ellipse_alpha; // Hide if b is too small
	if (b < 0.92 && hide_rear) { // Only do this after some angle of tilt
		col *= step(uv.y * normal.z, 0.0); // Hide rear (-z) side of ellipse. Why must we multiply uv.y?
	}
	return col;
}

bool on_square(float ypos, float size, vec2 norm) {
	return (distance(mouse_uv, norm * ypos) < size);
}

vec4 square(vec2 uv, float ypos, float size, float feather, vec2 norm, vec4 col, float highlight) {
	col.rgb += vec3(highlight);
	mat2 rm = mat2(vec2(-norm.y, norm.x), vec2(-norm.x, -norm.y));
	uv = rm * uv;
	uv += vec2(size / 2.0);
	col.a *= smoothstep(-feather, 0.0, uv.x) - smoothstep(size, size + feather, uv.x);
	col.a *= (smoothstep(ypos - feather, ypos, uv.y) - smoothstep(ypos + size, ypos + size + feather, uv.y));
	return col;
}

bool on_offset_circle(float ypos, float radius, vec2 norm) {
	return (distance(mouse_uv, norm * ypos) < radius);
}

vec4 offset_circle(vec2 uv, float ypos, float radius, float feather, vec2 norm, vec4 col, float highlight) {
	col.rgb += vec3(highlight);
	mat2 rm = mat2(vec2(-norm.y, norm.x), vec2(-norm.x, -norm.y));
	uv = rm * uv;
	return circle(uv - vec2(0.0, ypos), 0.0, radius, feather, col, 0.0);
}

vec4 line(vec2 uv, vec2 pos, float width, float feather, vec2 norm, vec4 col) {
	mat2 rm = mat2(vec2(-norm.y, norm.x), vec2(-norm.x, -norm.y));
	uv = rm * uv;
	col.a *= (smoothstep(uv.x - feather, uv.x, -width / 2.0) - smoothstep(uv.x, uv.x  + feather, width / 2.0));
	col.a *= (step(uv.y, pos.x) - step(uv.y, pos.y));
	return col;
}

void fragment() {
	//vec4 debug = vec4(1., 1., 0., step(UV.x, 0.1)) * step(0.9, UV.y);

	vec2 uv = 2.0 * UV - vec2(1.0); // -1 .. +1

	float r1hl = 0.0;
	float r2hl = 0.0;
	float dischl = 0.0;
	float exhl = 0.0;
	float eyhl = 0.0;
	float ezhl = 0.0;
	float sxhl = 0.0;
	float syhl = 0.0;
	float szhl = 0.0;
	float cxhl = 0.0;
	float cyhl = 0.0;
	float czhl = 0.0;

	vec2 vxn = normalize(vx.xy);
	vec2 vyn = normalize(vy.xy);
	vec2 vzn = normalize(vz.xy);

	float xm = length(vec2(vx.x, vx.y)); // Multiplier for length
	float ym = length(vec2(vy.x, vy.y));
	float zm = length(vec2(vz.x, vz.y));

	bool unhighlighted = true;

	if (on_offset_circle(small_circle_pos * xm, small_circle_radius, vxn)) {
		cxhl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && on_offset_circle(small_circle_pos * ym, small_circle_radius, vyn)) {
		cyhl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && on_offset_circle(small_circle_pos * zm, small_circle_radius, vzn)) {
		czhl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && on_square(square_pos * xm, square_size, vxn)) {
		sxhl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && on_square(square_pos * ym, square_size, vyn)) {
		syhl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && on_square(square_pos * zm, square_size, vzn)) {
		szhl = highlight_value;
		unhighlighted = false;
	}

	vec2 muv = vec2(mouse_uv.x, -mouse_uv.y);
	if (unhighlighted && ellipse(muv, asize, ellipse_thickness, smoothing, vx, colorx, exhl).a > 0.1) {
		unhighlighted = false;
		exhl = highlight_value;
	}
	if (unhighlighted && ellipse(muv, asize, ellipse_thickness, smoothing, vy, colory, eyhl).a > 0.1) {
		unhighlighted = false;
		eyhl = highlight_value;
	}
	if (unhighlighted && ellipse(muv, asize, ellipse_thickness, smoothing, vz, colorz, ezhl).a > 0.1) {
		unhighlighted = false;
		ezhl = highlight_value;
	}

	vec4 e1 = ellipse(uv, asize, ellipse_thickness, smoothing, vx, colorx, exhl);
	vec4 e2 = ellipse(uv, asize, ellipse_thickness, smoothing, vy, colory, eyhl);
	vec4 e3 = ellipse(uv, asize, ellipse_thickness, smoothing, vz, colorz, ezhl);

	float lm = length(mouse_uv);

	if (unhighlighted && lm < r1) {
		r1hl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && lm < disc_radius) {
		dischl = highlight_value;
		unhighlighted = false;
	}

	if (unhighlighted && lm < r2 && lm > (r2 - ring_thickness)) {
		r2hl = highlight_value;
	}

	vec4 ring1 = circle(uv, r1 - ring_thickness, r1, smoothing, ring_color, r1hl);
	vec4 ring2 = circle(uv, r2 - ring_thickness, r2, smoothing, ring_color, r2hl);
	vec4 disc = circle(uv, 0.0, disc_radius, smoothing, disc_color, dischl);

	vec4 s1 = square(uv, square_pos * xm, square_size, smoothing, vxn, colorx, sxhl);
	vec4 s2 = square(uv, square_pos * ym, square_size, smoothing, vyn, colory, syhl);
	vec4 s3 = square(uv, square_pos * zm, square_size, smoothing, vzn, colorz, szhl);

	vec4 c1 = offset_circle(uv, small_circle_pos * xm, small_circle_radius, smoothing, vxn, colorx, cxhl);
	vec4 c2 = offset_circle(uv, small_circle_pos * ym, small_circle_radius, smoothing, vyn, colory, cyhl);
	vec4 c3 = offset_circle(uv, small_circle_pos * zm, small_circle_radius, smoothing, vzn, colorz, czhl);

	vec4 l1 = line(uv, lx * xm, line_width, smoothing, vxn, colorx);
	vec4 l2 = line(uv, ly * ym, line_width, smoothing, vyn, colory);
	vec4 l3 = line(uv, lz * zm, line_width, smoothing, vzn, colorz);

	vec4 layer = mix(disc, ring1, ring1.a);
	layer = mix(layer, ring2, ring2.a);
	layer = mix(layer, e1, e1.a);
	layer = mix(layer, e2, e2.a);
	layer = mix(layer, e3, e3.a);
	if (show_x) {
		layer = mix(layer, l1, l1.a);
		layer = mix(layer, s1, s1.a);
		layer = mix(layer, c1, c1.a);
	}
	if (show_y) {
		layer = mix(layer, l2, l2.a);
		layer = mix(layer, s2, s2.a);
		layer = mix(layer, c2, c2.a);
	}
	if (show_z) {
		layer = mix(layer, l3, l3.a);
		layer = mix(layer, s3, s3.a);
		layer = mix(layer, c3, c3.a);
	}
	//layer = mix(layer, debug, debug.a);

	COLOR = layer;
}