shader_type canvas_item;
// Silgi: karıştırma kapalı, çizildiği yeri tamamen saydam yapar (fırça katmanından siler).
render_mode blend_disabled, unshaded;

void fragment() {
	COLOR = vec4(0.0);
}
