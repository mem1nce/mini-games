extends CanvasLayer
# Arka plan: üstte perdeli küçük bir sahne (mor fon, spot ışıkları, ışık zinciri, saçaklı üst perde,
# iple toplanmış yan perdeler, ahşap sahne tabanı); altta enstrümanlar için sıcak, yumuşak renkli zemin.
# layout() ekran boyutuna göre her şeyi yeniden yerleştirir (döşenen parçalar region ile tekrarlanır).

const G := "res://oyunlar/muzik_kutusu/gorseller/"
const TEX_TOP: Texture2D = preload(G + "perde_ust.svg")
const TEX_SIDE: Texture2D = preload(G + "perde_yan.svg")
const TEX_FLOOR: Texture2D = preload(G + "sahne_tabani.svg")
const TEX_LIGHTS: Texture2D = preload(G + "isiklar.svg")
const TEX_GLOW: Texture2D = preload(G + "isik.svg")
const TOP_SCALE := 0.62
const FLOOR_SCALE := 0.75
const FLOOR_SURFACE := 14.0             # tabanın üst yüzeyinde ayakların bastığı yer (sprite üstünden)

var _ground: TextureRect
var _backdrop: TextureRect
var _spots: Array[Sprite2D] = []
var _lights: Sprite2D
var _top: Sprite2D
var _left: Sprite2D
var _right: Sprite2D
var _floor: Sprite2D
var _time: float = 0.0


func _ready() -> void:
	layer = -1
	_ground = _gradient([Color("fff4e4"), Color("ffe6ef")])
	_backdrop = _gradient([Color("4b3a92"), Color("7d67d6")])
	for k in 4:
		var spot := Sprite2D.new()
		spot.texture = TEX_GLOW
		spot.modulate = Color(1.0, 0.95, 0.8, 0.28)
		add_child(spot)
		_spots.append(spot)
	_lights = _tiled(TEX_LIGHTS)
	_floor = _tiled(TEX_FLOOR)
	_left = Sprite2D.new()
	_left.texture = TEX_SIDE
	_left.centered = false
	add_child(_left)
	_right = Sprite2D.new()
	_right.texture = TEX_SIDE
	_right.centered = false
	_right.flip_h = true
	add_child(_right)
	_top = _tiled(TEX_TOP)
	# CanvasLayer üst düğümün süzgecini devralmaz: küçültülen SVG'ler mipmap ile yumuşak görünsün
	for child in get_children():
		(child as CanvasItem).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _gradient(colors: Array[Color]) -> TextureRect:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 128
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


# Yatayda döşenen sprite: doku tekrarlanır, genişlik region ile ayarlanır
func _tiled(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(sprite)
	return sprite


func _stretch(sprite: Sprite2D, svg_width: float, draw_scale: float, width: float, y: float) -> void:
	# SVG'ler 2x içe aktarıldı: tuval birimi başına doku pikseli
	var ratio := sprite.texture.get_width() / svg_width
	sprite.scale = Vector2.ONE * draw_scale / ratio
	sprite.region_rect = Rect2(0, 0, width / sprite.scale.x, sprite.texture.get_height())
	sprite.position = Vector2(0, y)


## floor_y: dansçıların ayak çizgisi; dancer_xs: dansçıların yatay konumları (spot ışıkları onların arkasında)
func layout(size: Vector2, floor_y: float, dancer_xs: Array[float]) -> void:
	var floor_top := floor_y - FLOOR_SURFACE
	_backdrop.position = Vector2.ZERO
	_backdrop.size = Vector2(size.x, floor_top + 4.0)
	_ground.position = Vector2(0, floor_top)
	_ground.size = Vector2(size.x, size.y - floor_top)
	_stretch(_floor, 320.0, FLOOR_SCALE, size.x, floor_top)
	_stretch(_top, 320.0, TOP_SCALE, size.x, 0.0)
	_stretch(_lights, 320.0, 0.8, size.x, 124.0 * TOP_SCALE - 16.0)
	var side_scale := (floor_top + 8.0) / 304.0
	for curtain in [_left, _right]:
		curtain.scale = Vector2.ONE * side_scale * 304.0 / curtain.texture.get_height()
	_left.position = Vector2.ZERO
	_right.position = Vector2(size.x - 160.0 * side_scale, 0)
	for k in _spots.size():
		_spots[k].visible = k < dancer_xs.size()
		if _spots[k].visible:
			_spots[k].position = Vector2(dancer_xs[k], floor_y - 70.0)
			_spots[k].scale = Vector2(210.0, 200.0) / TEX_GLOW.get_width()


func floor_bottom(floor_y: float) -> float:
	return floor_y - FLOOR_SURFACE + 76.0 * FLOOR_SCALE


func _process(delta: float) -> void:
	# Spot ışıkları çok hafif titreşir
	_time += delta
	for k in _spots.size():
		_spots[k].modulate.a = 0.24 + 0.05 * sin(_time * 1.3 + k * 1.7)
