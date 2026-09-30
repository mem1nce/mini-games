shader_type canvas_item;
// Yuvadaki siluetin dolgusu: nesnenin kendi görselinden, sadece saydamlığı kullanılır (tek düze soluk renk).
// COLOR.a düğümün modulate.a değerini de içerir (solma animasyonu çalışsın).

uniform vec4 fill_color : source_color = vec4(0.23, 0.18, 0.42, 0.13);

void fragment() {
	COLOR = vec4(fill_color.rgb, step(0.4, COLOR.a) * fill_color.a * clamp(COLOR.a * 2.5, 0.0, 1.0));
}
