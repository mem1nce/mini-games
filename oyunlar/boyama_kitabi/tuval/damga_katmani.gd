extends Node2D
# Fırça katmanında bir damga: seçili renkle çarpılan katman + üstünde kendi renkli ayrıntılar (yüz, parıltı).
# Konumu damganın ortası; dokunulunca küçükten büyüyüp hafifçe esneyerek yerleşir ("pıt").

var fill: Texture2D
var top: Texture2D
var color: Color = Color.WHITE
var size: float = 160.0


func _draw() -> void:
	var rect := Rect2(Vector2(-size, -size) * 0.5, Vector2(size, size))
	draw_texture_rect(fill, rect, false, color)
	if top:
		draw_texture_rect(top, rect, false)


func pop_in(time: float) -> void:
	scale = Vector2(0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), time * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, time * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func clone() -> Node2D:
	var copy: Node2D = get_script().new()
	copy.fill = fill
	copy.top = top
	copy.color = color
	copy.size = size
	copy.position = position
	copy.rotation = rotation
	return copy
