extends Node2D
# Oyun odası arka planı (gorseller/arka_plan.svg, 1280x720): ekranı tamamen kaplar ve resimdeki zemin
# çizgisi (y = 420) ekrandaki zemin çizgisine (yükseklik x 420/720, SizeLevelGenerator.FLOOR) denk gelir.

const TEXTURE: Texture2D = preload("res://oyunlar/buyukten_kucuge/gorseller/arka_plan.svg")
const ART_SIZE := Vector2(1280.0, 720.0)
const ART_FLOOR := 420.0

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.centered = false
	add_child(_sprite)


func layout(screen: Vector2) -> void:
	var s := maxf(screen.x / ART_SIZE.x, screen.y / ART_SIZE.y)
	var floor_y := screen.y * ART_FLOOR / ART_SIZE.y
	_sprite.scale = Vector2.ONE * s * ART_SIZE.x / TEXTURE.get_width()
	_sprite.position = Vector2(screen.x / 2.0 - ART_SIZE.x * s / 2.0, floor_y - ART_FLOOR * s)
