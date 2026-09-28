extends Node2D
# Gölge yuvası (ShadowSlot): eşyanın kendi görselini golge.gdshader ile koyu, yarı saydam
# bir siluet olarak çizer. Böylece gölge her zaman eşyayla birebir aynı şekildedir.

signal filled(slot: Node2D)

const SHADER: Shader = preload("res://oyunlar/golge_eslestirme/golge.gdshader")

var data: ShadowItemData
var size: float = 200.0
var is_filled: bool = false

var _sprite: Sprite2D
var _material: ShaderMaterial
var _hover: bool = false
var _tween: Tween


func setup(item_data: ShadowItemData, item_size: float, point: Vector2, color: Color) -> void:
	data = item_data
	size = item_size
	position = point
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("shadow_color", color)
	_sprite = Sprite2D.new()
	_sprite.texture = item_data.texture
	_sprite.scale = Vector2.ONE * item_size / item_data.texture.get_width()
	_sprite.material = _material
	add_child(_sprite)


# Doğru eşya üstüne gelince gölge hafifçe büyür ve aydınlanır
func set_hover(on: bool) -> void:
	if on == _hover or is_filled:
		return
	_hover = on
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_method(_set_glow, 1.0 - float(on), float(on), 0.18)


func fill() -> void:
	is_filled = true
	_hover = false
	var tween := _new_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.tween_method(_set_glow, 1.0, 0.0, 0.3)
	filled.emit(self)


func appear(delay: float) -> void:
	scale = Vector2.ZERO
	var tween := _new_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear(delay: float) -> void:
	var tween := _new_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _set_glow(value: float) -> void:
	_material.set_shader_parameter("glow", value)


func _new_tween() -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	return _tween
