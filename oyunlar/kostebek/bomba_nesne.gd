extends "res://oyunlar/kostebek/cikan_nesne.gd"
# Bomb: klasik yuvarlak bomba; fitilinin ucunda kıvılcım titrer, bomba hafifçe sallanır.
# Dokununca kaybolur, yerine yumuşak bir duman bulutu çıkar (efekti oyun ekler). Korkutucu değil.

const G := "res://oyunlar/kostebek/gorseller/"
const TEX_BOMB: Texture2D = preload(G + "bomba.svg")
const TEX_SPARK: Texture2D = preload(G + "kivilcim.svg")
const SIZE := 190.0
const FUSE_TIP := Vector2(56.0, -112.0) * SIZE / 256.0   # tuvalde (184,16), merkeze göre

var _body: Node2D
var _spark: Sprite2D


func _init() -> void:
	kind = Kind.BOMB
	up_y = -75.0
	down_y = 150.0
	visual_rect = Rect2(-70, -86, 140, 156)


func setup() -> void:
	_body = Node2D.new()
	add_child(_body)
	var bomb := Sprite2D.new()
	bomb.texture = TEX_BOMB
	bomb.scale = Vector2.ONE * 0.5 * SIZE / 256.0
	_body.add_child(bomb)
	_spark = Sprite2D.new()
	_spark.texture = TEX_SPARK
	_spark.position = FUSE_TIP
	_body.add_child(_spark)


func _process(delta: float) -> void:
	super(delta)
	if _body == null or was_hit:
		return
	# Fitil yanarken: kıvılcım titreşir/döner, bomba çok hafif titrer
	_spark.scale = Vector2.ONE * 0.5 * randf_range(0.42, 0.62)
	_spark.rotation = randf() * TAU
	_spark.modulate.a = randf_range(0.8, 1.0)
	_body.rotation = sin(_time * 22.0) * 0.035
	_body.position.x = sin(_time * 31.0) * 1.2


func _on_hit() -> void:
	was_hit = true
	hittable = false
	if _tween:
		_tween.kill()
	# Bomba "puf" diye kaybolur: kısa büyüyüp söner (duman bulutu onun yerini alır)
	_tween = create_tween()
	_tween.tween_property(_body, "scale", Vector2(1.15, 1.15), 0.06)
	_tween.tween_property(_body, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish)
	hit.emit(self, HitResult.BOMB)
