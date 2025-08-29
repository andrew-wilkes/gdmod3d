shader_type canvas_item;

uniform float highlight = 0.0;
uniform float select = 0.0;

void fragment() {
	COLOR.rgb += vec3(max(highlight, select));
}
