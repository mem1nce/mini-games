extends Node2D
# İpucu eli (HintHand): çocuk bir süre bir şey yapmazsa bir eşyanın üstüne iner, "basar",
# eşyanın kendi gölgesine kayar ve kaybolur. Düğümün konumu parmak ucudur.

const TEXTURE: Texture2D = preload("res://oyunlar/golge_eslestirme/gorseller/el.svg")
const TIP := Vector2(112.0, 12.0)    # el.svg içinde parmak ucunun yeri (256x256 çizimde)
const TILT := -0.26                  # el hafif sağa yatık dursun

var _sprite: Sprite2D
var _tween: Tween


func _ready() -> void:
	visible = false
	z_index = 20
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	# Sprite ortalanır; parmak ucu düğümün tam konumuna gelsin diye kaydırılır
	var pixels_per_unit := TEXTURE.get_width() / 256.0
	_sprite.offset = (Vector2(128.0, 128.0) - TIP) * pixels_per_unit
	add_child(_sprite)


func set_hand_size(pixels: float) -> void:
	_sprite.scale = Vector2.ONE * pixels / TEXTURE.get_width()


func play(from: Vector2, to: Vector2) -> void:
	stop()
	visible = true
	rotation = TILT
	position = from + Vector2(60.0, 90.0)
	scale = Vector2.ONE
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_tween.parallel().tween_property(self, "position", from, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Basma
	_tween.tween_property(self, "scale", Vector2.ONE * 0.85, 0.15)
	# Gölgeye taşıma
	_tween.tween_property(self, "position", to, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Bırakma
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	_tween.tween_interval(0.25)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(hide)


func stop() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	if visible:
		# Dokunulunca el hemen ama yumuşakça kaybolsun
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 0.0, 0.12)
		_tween.tween_callback(hide)


func is_playing() -> bool:
	return visible and _tween != null and _tween.is_running()
