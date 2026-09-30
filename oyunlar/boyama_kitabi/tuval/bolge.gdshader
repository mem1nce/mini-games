shader_type canvas_item;
// Bölge boyası: bölge haritasından (TEXTURE, 8 bit gri, en yakın örnekleme) pikselin bölge numarasını okur,
// palet dokusundan (256x1, her piksel bir bölgenin rengi) o bölgenin rengini alır.
// Kova animasyonu: anim_region bölgesinde, anim_center'dan dışa büyüyen dairenin dışı eski renkte kalır;
// dalga cephesi hafifçe parlar.

uniform sampler2D palette : filter_nearest;
uniform int anim_region = -1;
uniform vec2 anim_center = vec2(0.0);   // tuval pikseli
uniform float anim_radius = 0.0;        // tuval pikseli
uniform vec4 anim_old_color = vec4(1.0);
uniform vec2 tex_size = vec2(2048.0, 1536.0);

void fragment() {
	int id = int(texture(TEXTURE, UV).r * 255.0 + 0.5);
	vec4 color = texelFetch(palette, ivec2(id, 0), 0);
	if (id == anim_region) {
		float d = distance(UV * tex_size, anim_center);
		float edge = 14.0;
		float outside = smoothstep(anim_radius - edge, anim_radius, d);
		float glow = 1.0 - abs(outside * 2.0 - 1.0);
		color = mix(mix(color, vec4(1.0), 0.45 * glow), anim_old_color, outside);
	}
	COLOR = vec4(color.rgb, 1.0);
}
