extends CanvasLayer
# Arka plan (ekran koordinatında): açık mavi gök, 3 paralaks bulut katmanı ve başlangıçtaki mavi tepeler.
# Katmanlar hem yatayda hem dikeyde döşenebilir SVG'lerdir (gorseller/svg_uret.py); Sprite2D'nin
# region_rect'i kaydırılarak sonsuz tekrarlanır. Kamera yükseldikçe uzak katman yavaş, yakın katman
# daha hızlı kayar; bulutlar ayrıca yatayda çok yavaş süzülür.

const G := "res://oyunlar/zipla_zipla/gorseller/"
const LAYERS := ["arka_uzak", "arka_orta", "arka_yakin"]
const FACTOR := [0.12, 0.25, 0.45]       # kameranın yükselişinin ne kadarı kadar kayar
const DRIFT := [7.0, 4.0, 0.0]           # yatay süzülme (px/sn)
const HILLS_FACTOR := 0.5
const HILLS_VISIBLE := 250.0             # başlangıçta tepelerin ekranın altında görünen yüksekliği
const SKY_TOP := Color("79c2f7")
const SKY_BOTTOM := Color("d4eeff")

var _sky: TextureRect
var _layers: Array[Sprite2D] = []
var _hills: Sprite2D
var _height: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	layer = -10
	var root := Node2D.new()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(root)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([SKY_TOP, SKY_BOTTOM])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.width = 8
	texture.height = 256
	_sky = TextureRect.new()
	_sky.texture = texture
	_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky.stretch_mode = TextureRect.STRETCH_SCALE
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sky)
	for name in LAYERS:
		var sprite := Sprite2D.new()
		sprite.texture = load(G + name + ".svg")
		sprite.centered = false
		sprite.region_enabled = true
		root.add_child(sprite)
		_layers.append(sprite)
	_hills = Sprite2D.new()
	_hills.texture = load(G + "tepeler.svg")
	_hills.centered = false
	_hills.region_enabled = true
	root.add_child(_hills)
	_update()


# Kameranın başlangıçtan beri ne kadar yükseldiği (px)
func set_height(height: float) -> void:
	_height = height


func _process(delta: float) -> void:
	_time += delta
	_update()


func _update() -> void:
	var screen := get_viewport().get_visible_rect().size
	_sky.size = screen
	for k in _layers.size():
		var sprite := _layers[k]
		var offset := Vector2(-_time * DRIFT[k] + k * 310.0, -_height * FACTOR[k] + k * 170.0)
		sprite.region_rect = Rect2(offset, screen)
	# Tepeler dünyayla birlikte (daha yavaş) aşağı kayar; ekranın altından çıkınca görünmez
	_hills.region_rect = Rect2(0, 0, screen.x, _hills.texture.get_height())
	_hills.position = Vector2(0, screen.y - HILLS_VISIBLE + _height * HILLS_FACTOR)
	_hills.visible = _hills.position.y < screen.y
