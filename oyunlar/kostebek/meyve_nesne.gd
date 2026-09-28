extends "res://oyunlar/kostebek/cikan_nesne.gd"
# Fruit: rastgele bir meyve ya da sebze. Dokununca zıplayıp küçülerek kaybolur (parıltıyı oyun ekler).
# Koyu mor/siyah meyve yok: bomba ile asla karışmasın.

const G := "res://oyunlar/kostebek/gorseller/"
const TEXTURES: Array[Texture2D] = [
	preload(G + "elma.svg"), preload(G + "muz.svg"), preload(G + "cilek.svg"), preload(G + "portakal.svg"),
	preload(G + "karpuz.svg"), preload(G + "uzum.svg"), preload(G + "havuc.svg"), preload(G + "domates.svg"),
]
# Parçacık rengi (TEXTURES ile aynı sıra)
const COLORS: Array[Color] = [
	Color("8fd14f"), Color("ffd84a"), Color("ff4f6e"), Color("ff9f2e"),
	Color("ff5a6e"), Color("b8e05a"), Color("ff8a1f"), Color("ff4a3a"),
]
const SIZE := 190.0   # çukur biriminde genişlik

var color: Color = Color.WHITE
var _sprite_node: Sprite2D


func _init() -> void:
	kind = Kind.FRUIT
	up_y = -80.0
	down_y = 160.0
	visual_rect = Rect2(-SIZE / 2.0, -SIZE / 2.0, SIZE, SIZE)


func setup(index: int = -1) -> void:
	if index < 0:
		index = randi() % TEXTURES.size()
	color = COLORS[index]
	_sprite_node = _sprite(TEXTURES[index], SIZE / 256.0)
	_sprite_node.rotation = randf_range(-0.15, 0.15)


func _process(delta: float) -> void:
	super(delta)
	# Dururken hafifçe sallanır
	if phase == Phase.UP and not was_hit:
		_sprite_node.rotation = sin(_time * 3.0) * 0.08


func _on_hit() -> void:
	was_hit = true
	hittable = false
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", position.y - 70.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "scale", Vector2(1.25, 1.25), 0.14)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)
	hit.emit(self, HitResult.FRUIT)
