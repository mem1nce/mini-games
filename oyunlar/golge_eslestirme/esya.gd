extends "res://ortak/suruklenebilir.gd"
# Sürüklenebilir eşya. Yakalanma, parmağı izleme, geri kayma ve kutlama animasyonları ortak
# DraggableItem'dan (ortak/suruklenebilir.gd) gelir; dokunmayı ortak DragInput yönetir.
# Burada sadece eşyanın görseli ve gölgesine oturma animasyonu var.

const Slot := preload("res://oyunlar/golge_eslestirme/golge_yuvasi.gd")

const Z_PLACED := 0

var data: ShadowItemData
var slot: Slot                   # bu eşyanın kendi gölgesi
var placed: bool = false

var _sprite: Sprite2D


func setup(item_data: ShadowItemData, item_size: float, start: Vector2) -> void:
	data = item_data
	setup_drag(item_size, start)
	_sprite = Sprite2D.new()
	_sprite.texture = item_data.texture
	_sprite.scale = Vector2.ONE * item_size / item_data.texture.get_width()
	add_child(_sprite)


func can_grab() -> bool:
	return not placed


# Gölgenin üstüne oturur: küçük bir büyüme-küçülme ile
func snap_to(point: Vector2, duration: float) -> void:
	dragging = false
	placed = true
	z_index = Z_PLACED
	var tween := _new_tween()
	tween.tween_property(self, "position", point, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", 0.0, duration)
	tween.tween_property(self, "scale", Vector2.ONE * 1.22, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
