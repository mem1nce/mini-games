extends Node2D
# Sıcak çiftlik bahçesi: gökyüzü, gülen güneş, yavaş bulutlar, uzak ve yakın tepeler, beyaz çit, çimen,
# çiçekler ve altta ahşap piknik masası. Her şey ekran boyutuna göre layout() ile yerleşir
# (masa ekranın tam genişliğinde, üst yüzü table_top'ta).

const TEX_SUN: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/gunes.svg")
const TEX_CLOUD: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/bulut.svg")
const TEX_HILL_FAR: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/tepe_uzak.svg")
const TEX_HILL_NEAR: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/tepe_yakin.svg")
const TEX_FENCE: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/cit.svg")
const TEX_FLOWER: Texture2D = preload("res://oyunlar/hayvan_besle/gorseller/cicek.svg")

const SKY_TOP := Color("8fd3ff")
const SKY_BOTTOM := Color("e4f6ff")
const GRASS := Color("7cc862")
const OUT := Color("3b2f6b")
const WOOD := Color("f0b56e")
const WOOD_LIGHT := Color("ffd39a")
const WOOD_DARK := Color("c98a4a")

var screen := Vector2(1280, 720)
var table_top: float = 540.0

var _clouds: Array[Sprite2D] = []
var _sun: Sprite2D
var _decor: Node2D                  # tepeler, çit, çiçekler (layout'ta yeniden kurulur)


func _ready() -> void:
	for k in 3:
		var cloud := Sprite2D.new()
		cloud.texture = TEX_CLOUD
		cloud.modulate.a = randf_range(0.8, 0.95)
		cloud.set_meta("speed", randf_range(6.0, 12.0))
		add_child(cloud)
		_clouds.append(cloud)
	_sun = Sprite2D.new()
	_sun.texture = TEX_SUN
	add_child(_sun)
	_decor = Node2D.new()
	add_child(_decor)


func layout(screen_size: Vector2, top_of_table: float) -> void:
	screen = screen_size
	table_top = top_of_table
	var horizon := table_top - (table_top - 90.0) * 0.42      # çitin ayak hizası
	_sun.scale = Vector2.ONE * 130.0 / TEX_SUN.get_width()
	_sun.position = Vector2(screen.x - 80.0, 76.0)
	for k in _clouds.size():
		var cloud := _clouds[k]
		cloud.scale = Vector2.ONE * randf_range(170.0, 230.0) / TEX_CLOUD.get_width()
		cloud.position = Vector2(screen.x * (0.15 + 0.33 * k), randf_range(120.0, horizon - 140.0))
	for child in _decor.get_children():
		child.queue_free()
	_stretch(TEX_HILL_FAR, horizon - 150.0, 220.0)
	_stretch(TEX_HILL_NEAR, horizon - 70.0, 170.0)
	# Çit: parçalar yan yana
	var fence_h := 110.0
	var fence_w := fence_h * 160.0 / 150.0
	var x := -fence_w * 0.3
	while x < screen.x + fence_w:
		var piece := Sprite2D.new()
		piece.texture = TEX_FENCE
		piece.centered = false
		piece.scale = Vector2.ONE * fence_h / (TEX_FENCE.get_height())
		piece.position = Vector2(x, horizon - fence_h * 0.9)
		_decor.add_child(piece)
		x += fence_w
	# Çimende birkaç çiçek
	var grass_rect := Rect2(0.0, horizon, screen.x, table_top - horizon)
	for k in int(screen.x / 170.0):
		var flower := Sprite2D.new()
		flower.texture = TEX_FLOWER
		flower.scale = Vector2.ONE * randf_range(34.0, 46.0) / TEX_FLOWER.get_width()
		flower.position = Vector2((k + randf_range(0.2, 0.8)) * 170.0, grass_rect.position.y + randf_range(0.15, 0.55) * grass_rect.size.y)
		flower.modulate = [Color.WHITE, Color("ffd6e8"), Color("fff3b0")][k % 3]
		_decor.add_child(flower)
	queue_redraw()


func _stretch(texture: Texture2D, top: float, height: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(0.0, top)
	sprite.scale = Vector2(screen.x / texture.get_width(), height / texture.get_height())
	_decor.add_child(sprite)


func _process(delta: float) -> void:
	for cloud in _clouds:
		cloud.position.x += float(cloud.get_meta("speed")) * delta
		var half := cloud.texture.get_width() * cloud.scale.x / 2.0
		if cloud.position.x > screen.x + half:
			cloud.position.x = -half
	_sun.rotation = sin(Time.get_ticks_msec() / 1000.0 * 0.5) * 0.05


func _draw() -> void:
	# Gökyüzü (dikey geçiş) ve çimen
	var sky := PackedVector2Array([Vector2.ZERO, Vector2(screen.x, 0), Vector2(screen.x, table_top), Vector2(0, table_top)])
	draw_polygon(sky, PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	var horizon := table_top - (table_top - 90.0) * 0.42
	draw_rect(Rect2(0, horizon, screen.x, screen.y - horizon), GRASS)


# Masa: ayrı bir düğüm çağırır (hayvanların önünde, yiyeceklerin arkasında). Hafif yukarıdan görülen
# geniş ahşap yüzey; üst kenarında açık renkli pervaz, üstünde tahta çizgileri.
static func draw_table(canvas: CanvasItem, screen_size: Vector2, top: float) -> void:
	var rect := Rect2(-20.0, top, screen_size.x + 40.0, screen_size.y - top + 40.0)
	var box := StyleBoxFlat.new()
	box.bg_color = WOOD
	box.border_color = OUT
	box.set_border_width_all(6)
	box.set_corner_radius_all(26)
	box.anti_aliasing = true
	box.shadow_color = Color(OUT, 0.18)
	box.shadow_size = 12
	box.shadow_offset = Vector2(0, -4)
	canvas.draw_style_box(box, rect)
	var plank := 48.0
	var y := top + 30.0
	while y < screen_size.y:
		canvas.draw_line(Vector2(0, y), Vector2(screen_size.x, y), Color(WOOD_DARK, 0.55), 3.0)
		y += plank
	canvas.draw_rect(Rect2(0, top + 8.0, screen_size.x, 10.0), Color(WOOD_LIGHT, 0.9))
	canvas.draw_line(Vector2(0, top + 24.0), Vector2(screen_size.x, top + 24.0), Color(OUT, 0.35), 3.0)
