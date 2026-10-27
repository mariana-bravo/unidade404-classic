shader_type canvas_item;
render_mode unshaded;
varying vec4 icon_tint;
void vertex() { icon_tint = COLOR; }
void fragment() {
	vec4 tint = icon_tint;
	vec4 pixel = texture(TEXTURE, UV);
	float ink = 1.0 - min(pixel.r, min(pixel.g, pixel.b));
	float alpha = smoothstep(0.06, 0.18, ink);
	COLOR = vec4(pixel.rgb * tint.rgb, alpha * tint.a);
}
