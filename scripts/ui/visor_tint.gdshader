shader_type canvas_item;
render_mode unshaded;
uniform vec4 visor_color : source_color = vec4(0.573, 0.863, 0.729, 1.0);
void fragment() {
	COLOR = vec4(visor_color.rgb, texture(TEXTURE, UV).a * visor_color.a);
}
