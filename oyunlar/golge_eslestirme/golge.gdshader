shader_type canvas_item;
// Eşyanın kendi görselinden siluet: sadece saydamlığı kullanılır, renk tek düze gölge rengi olur.
// COLOR.a hem dokunun saydamlığını hem de düğümün modulate.a değerini içerir (solma animasyonları çalışsın).

uniform vec4 shadow_color : source_color = vec4(0.16, 0.18, 0.4, 0.58);
// Üzerine doğru eşya gelince gölge hafifçe aydınlanır
uniform float glow : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 color = mix(shadow_color.rgb, vec3(1.0), glow * 0.35);
	COLOR = vec4(color, COLOR.a * shadow_color.a * (1.0 - glow * 0.25));
}
