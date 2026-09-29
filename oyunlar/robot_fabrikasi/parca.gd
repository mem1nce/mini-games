extends Node2D
# Tek robot parçası: görünüm (tür, renk, şekil, boyut), bantta hafif sallanma, tutulma ve uçuş animasyonları.
# Düğümün (0, 0) noktası parçanın ortası; bantta dururken alt kenarı bandın yüzeyine değer.

const G := "res://oyunlar/robot_fabrikasi/gorseller/parcalar/"
const SIZES := {"normal": 112.0, "buyuk": 150.0, "kucuk": 78.0}

var data: Dictionary = {}              # kind, color, shape, size
var for_box := -1                      # hangi kutu için üretildi
var held := false
var on_belt := true

var _sprite: Sprite2D
var _time := 0.0
var _phase := 0.0


static func texture_for(part: Dictionary) -> Texture2D:
	var kind: String = part["kind"]
	if part.get("shape", "") != "":
		return load(G + "%s_%s_%s.svg" % [kind, part["shape"], part["color"]])
	return load(G + "%s_%s.svg" % [kind, part["color"]])


static func size_px(part: Dictionary) -> float:
	return SIZES.get(part.get("size", "normal"), SIZES["normal"])


func setup(part: Dictionary, box: int) -> void:
	data = part
	for_box = box
	_sprite = Sprite2D.new()
	_sprite.texture = texture_for(part)
	_sprite.scale = Vector2.ONE * size_px(part) / _sprite.texture.get_width()
	add_child(_sprite)
	_phase = randf() * TAU


func radius() -> float:
	return size_px(data) * 0.42


# Parçanın alt kenarı ile merkezi arası (banda oturtmak için)
func half_height() -> float:
	return size_px(data) * 0.42


func contains(point: Vector2) -> bool:
	return global_position.distance_to(point) < maxf(radius() + 14.0, 58.0)


func pick() -> void:
	held = true
	on_belt = false
	z_index = 10
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func release() -> void:
	held = false
	z_index = 0
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)


func highlight(value: bool) -> void:
	modulate = Color(1.25, 1.25, 1.1) if value else Color.WHITE


func _process(delta: float) -> void:
	_time += delta
	if on_belt:
		_sprite.rotation = sin(_time * 3.0 + _phase) * 0.05
		_sprite.position.y = -absf(sin(_time * 3.0 + _phase)) * 2.5
	elif held:
		_sprite.rotation = sin(_time * 8.0) * 0.06
		_sprite.position.y = 0.0
