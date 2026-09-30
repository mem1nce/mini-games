extends "res://ortak/suruklenebilir.gd"
# Yiyecek (FoodItem): masadaki tabakta durur, sürüklenip bir hayvana verilir. Yakalanma, parmağı izleme,
# yerine dönme ve gelme/gitme animasyonları ortak DraggableItem'dan (ortak/suruklenebilir.gd) gelir;
# dokunmayı ortak DragInput yönetir. Burada görsel ve hayvanın ağzına küçülerek girme var.

var data: FeedFoodData
## Hayvana verildi (ağza uçuyor ya da yendi): artık tutulamaz
var eaten: bool = false

var _sprite: Sprite2D


func setup(food: FeedFoodData, item_size: float, start: Vector2) -> void:
	data = food
	setup_drag(item_size, start)
	_sprite = Sprite2D.new()
	_sprite.texture = food.texture
	_sprite.scale = Vector2.ONE * item_size / food.texture.get_width()
	add_child(_sprite)


func can_grab() -> bool:
	return not eaten


# Hayvanın ağzına doğru uçar ve küçülerek kaybolur (target global konum)
func fly_into(target: Vector2, duration: float) -> void:
	eaten = true
	dragging = false
	z_index = Z_DRAGGED
	var tween := _new_tween()
	tween.tween_property(self, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.55, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
