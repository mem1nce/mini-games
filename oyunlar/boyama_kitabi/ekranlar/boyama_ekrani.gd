class_name ColoringScreen
extends Control
# Boyama ekranı: solda (basılı tutulan) geri düğmesi ve renk paleti, ortada tuval, sağda araç çubuğu.
# Dokunma: her parmak (index) bastığı yerin sahibine gider (geri, büyüteç, palet, araçlar, tuval) ve
# bırakılana kadar orada kalır. Tuvalde tek parmak boyar, iki parmak yakınlaştırır/kaydırır.
# Kayıt: kaydet düğmesi (kutlamayla), geri dönerken, uygulama arka plana alınırken ya da oyundan çıkılırken
# (SahneGecis sahneyi durdurunca: NOTIFICATION_DISABLED) otomatik. Değişiklik yoksa yazılmaz.

signal back_requested

const Settings := preload("res://oyunlar/boyama_kitabi/ayarlar.gd")
const BackButton := preload("res://ortak/basili_geri_dugmesi.gd")
const BucketTool := preload("res://oyunlar/boyama_kitabi/araclar/kova.gd")
const BrushTool := preload("res://oyunlar/boyama_kitabi/araclar/firca.gd")
const EraserTool := preload("res://oyunlar/boyama_kitabi/araclar/silgi.gd")
const StampTool := preload("res://oyunlar/boyama_kitabi/araclar/damga.gd")
const G := "res://oyunlar/boyama_kitabi/gorseller/"

const SIDE := 40.0                    # kenarlardan (çentik) uzaklık
const LEFT := 196.0                   # sol sütun (geri + palet) genişliği
const BG := Color("f1ecfb")
const PANEL := Color(1, 1, 1, 0.6)
## Kalınlıklar 2048'lik tuvalde piksel (ayarlar.gd CANVAS_LONG_SIDE ile orantılı büyür/küçülür)
const BRUSH_WIDTHS := [14.0, 32.0, 64.0]
const ERASER_WIDTHS := [34.0, 70.0, 130.0]
const STAMP_SIZE := 190.0

## Son seçilen renk ve araç (oyun açıkken korunur)
static var last_color: int = 0
static var last_tool: String = "kova"

var page_id: String = ""
var art_id: String = ""
var sounds: Node
var canvas: ColoringCanvas
var palette: ColoringPalette
var toolbar: ColoringToolBar
var back: Control
var zoom_button: ColoringIconButton
var _tools := {}
var _owners := {}                     # parmak index -> sahibi
var _saving: bool = false
var _leaving: bool = false


func setup(sound_pool: Node, page: String, artwork: String) -> void:
	sounds = sound_pool
	page_id = page
	art_id = artwork
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var saved := ColoringArtworks.load_art(art_id)
	if saved.is_empty():
		art_id = ""
	canvas = ColoringCanvas.new()
	add_child(canvas)
	canvas.setup(page_id, saved.get("colors", PackedColorArray()), saved.get("brush", null))
	canvas.sound.connect(func(name: String, pitch: float) -> void: sounds.play(name, pitch))
	canvas.zoom_changed.connect(_on_zoom_changed)
	palette = ColoringPalette.new()
	add_child(palette)
	palette.select(last_color)
	palette.color_selected.connect(_on_color)
	toolbar = ColoringToolBar.new()
	add_child(toolbar)
	toolbar.tool_chosen.connect(_on_tool)
	toolbar.option_chosen.connect(func(_i: int) -> void:
		sounds.play("tik")
		_apply_tool())
	toolbar.undo_pressed.connect(_on_undo)
	toolbar.save_pressed.connect(func() -> void: save(true))
	toolbar.clear_completed.connect(_on_clear)
	back = BackButton.new()
	back.size = Vector2(96, 96)
	back.completed.connect(_leave)
	add_child(back)
	zoom_button = ColoringIconButton.new()
	zoom_button.icon = load(G + "buyutec.svg")
	zoom_button.size = Vector2(78, 78)
	zoom_button.visible = false
	add_child(zoom_button)
	var scale_factor: float = Settings.CANVAS_LONG_SIDE / 2048.0
	_tools = {"kova": BucketTool.new(), "firca": BrushTool.new(), "gokkusagi": BrushTool.new(),
		"damga": StampTool.new(), "silgi": EraserTool.new()}
	_tools["gokkusagi"].rainbow = true
	_tools["damga"].size = STAMP_SIZE * scale_factor
	for tool: ColoringTool in _tools.values():
		tool.canvas = canvas
	toolbar.select_tool(last_tool)
	toolbar.set_color(palette.color())
	_apply_tool()
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	back.position = Vector2(SIDE, 14)
	palette.position = Vector2(SIDE - 12.0, 120)
	palette.size = Vector2(LEFT - SIDE + 12.0 - 8.0, size.y - 124)
	toolbar.size = Vector2(ColoringToolBar.CELL * 2.0 + 8.0, size.y - 16)
	toolbar.position = Vector2(size.x - SIDE - toolbar.size.x + 8.0, 10)
	canvas.position = Vector2(LEFT, 6)
	canvas.size = Vector2(toolbar.position.x - 8.0 - LEFT, size.y - 12)
	zoom_button.position = canvas.position + Vector2(canvas.size.x - zoom_button.size.x - 14.0, 14.0)
	zoom_button.pivot_offset = zoom_button.size * 0.5
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.set_corner_radius_all(30)
	draw_style_box(panel, Rect2(palette.position - Vector2(0, 4), palette.size + Vector2(0, 2)))
	draw_style_box(panel, Rect2(toolbar.position - Vector2(4, 2), Vector2(toolbar.size.x + 8, ColoringToolBar.CELL * 4.0 + 6.0)))


# --- Araç ve renk ---

func _apply_tool() -> void:
	var id := toolbar.current
	var tool: ColoringTool = _tools[id]
	var scale_factor: float = Settings.CANVAS_LONG_SIDE / 2048.0
	tool.color = palette.color()
	match id:
		"firca", "gokkusagi":
			tool.width = BRUSH_WIDTHS[toolbar.option()] * scale_factor
		"silgi":
			tool.width = ERASER_WIDTHS[toolbar.option()] * scale_factor
		"damga":
			tool.kind = toolbar.option()
	if canvas.tool != tool:
		canvas.release_all()
	canvas.tool = tool
	last_tool = id


func _on_tool(_id: String) -> void:
	sounds.play("tik")
	_apply_tool()


func _on_color(index: int) -> void:
	last_color = index
	sounds.play_color(index)
	toolbar.set_color(palette.color())
	_apply_tool()


func _on_undo() -> void:
	if canvas.undo():
		sounds.play("geri_al")
		toolbar.undo_button.bounce()
	else:
		toolbar.undo_button.shake()


func _on_clear() -> void:
	canvas.release_all()
	canvas.clear_all()
	sounds.play("temizle")
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.85)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = canvas.position
	flash.size = canvas.size
	add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)


func _on_zoom_changed(zoomed: bool) -> void:
	if zoomed == zoom_button.visible:
		return
	zoom_button.visible = true
	zoom_button.scale = Vector2.ONE * (0.2 if zoomed else 1.0)
	var tween := zoom_button.create_tween()
	tween.tween_property(zoom_button, "scale", Vector2.ONE * (1.0 if zoomed else 0.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not zoomed:
		tween.tween_callback(func() -> void: zoom_button.visible = false)


func _process(delta: float) -> void:
	var loop := ""
	if canvas and canvas.tool_active():
		loop = canvas.tool.loop_sound()
	sounds.set_loop(loop, canvas.loop_level if canvas else 0.0, delta)


# --- Dokunma ---

func handle_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_down(event.index, event.position)
		else:
			_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_move(event.index, event.position)
	elif event is InputEventMouseButton and event.pressed:
		var wheel: int = event.button_index
		if (wheel == MOUSE_BUTTON_WHEEL_UP or wheel == MOUSE_BUTTON_WHEEL_DOWN) and canvas.get_global_rect().has_point(event.position):
			canvas.zoom_at(event.position - canvas.global_position, 1.15 if wheel == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)


func _down(index: int, pos: Vector2) -> void:
	var owner := ""
	if back.contains(pos):
		owner = "back"
		back.press()
	elif zoom_button.visible and zoom_button.contains(pos):
		owner = "zoom"
		zoom_button.press()
	elif palette.contains(pos):
		owner = "palette"
		palette.press(pos)
	elif toolbar.contains(pos):
		owner = "tools"
		toolbar.press(pos)
	elif canvas.get_global_rect().has_point(pos):
		owner = "canvas"
		canvas.touch_down(index, pos)
	if owner != "":
		_owners[index] = owner


func _move(index: int, pos: Vector2) -> void:
	match _owners.get(index, ""):
		"palette":
			palette.drag(pos)
		"canvas":
			canvas.touch_move(index, pos)


func _up(index: int, pos: Vector2) -> void:
	var owner: String = _owners.get(index, "")
	_owners.erase(index)
	match owner:
		"back":
			back.release()
		"zoom":
			zoom_button.release()
			if zoom_button.contains(pos):
				sounds.play("tik")
				canvas.reset_view()
		"palette":
			palette.release(pos)
		"tools":
			toolbar.release(pos)
		"canvas":
			canvas.touch_up(index, pos)


# --- Kayıt ---

## Değişiklik varsa kaydeder (bir kare bekleyip son çizimin görüntüye geçmesini sağlar).
## celebrate: kaydet düğmesiyle; resim çerçevede parlar ve kaydet düğmesine uçar.
func save(celebrate: bool) -> void:
	if _saving:
		return
	if not canvas.dirty and art_id == "":
		if celebrate:
			toolbar.save_button.shake()
		return
	_saving = true
	if celebrate:
		toolbar.save_button.bounce()
	if canvas.dirty:
		await RenderingServer.frame_post_draw
		if not is_inside_tree():
			return
		_write()
	_saving = false
	if celebrate:
		_celebrate()


## Beklemeden kaydeder (uygulama arka plana alınırken, oyundan çıkılırken)
func save_now() -> void:
	if canvas and canvas.dirty:
		_write()


func _write() -> void:
	var brush := canvas.brush_image() if canvas.has_brush_content() else null
	art_id = ColoringArtworks.save_art(art_id, page_id, canvas.colors, brush, canvas.thumbnail())
	canvas.dirty = false


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	canvas.release_all()
	for index in _owners:
		if _owners[index] == "tools":
			toolbar.cancel()
	_owners.clear()
	await save(false)
	back_requested.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_DISABLED:
			if not _saving:
				save_now()


# Kutlama: sayfa çerçevesi parlar, resim küçülerek kaydet düğmesine uçar
func _celebrate() -> void:
	sounds.play("kaydet")
	var rect := Rect2(canvas.global_position + canvas.page_rect().position, canvas.page_rect().size)
	var glow := Control.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var sparks: Array[Vector2] = []
	for i in 14:
		var t := i / 14.0
		var perimeter := t * 2.0 * (rect.size.x + rect.size.y)
		var p := rect.position
		if perimeter < rect.size.x:
			p += Vector2(perimeter, 0)
		elif perimeter < rect.size.x + rect.size.y:
			p += Vector2(rect.size.x, perimeter - rect.size.x)
		elif perimeter < 2.0 * rect.size.x + rect.size.y:
			p += Vector2(rect.size.x - (perimeter - rect.size.x - rect.size.y), rect.size.y)
		else:
			p += Vector2(0, rect.size.y - (perimeter - 2.0 * rect.size.x - rect.size.y))
		sparks.append(p)
	glow.draw.connect(func() -> void:
		var t: float = glow.get_meta("t", 0.0)
		var alpha := sin(t * PI)
		glow.draw_rect(rect.grow(10.0), Color(1.0, 0.82, 0.25, 0.9 * alpha), false, 12.0 * alpha + 2.0)
		for k in sparks.size():
			var s := (10.0 + 10.0 * sin(t * TAU * 2.0 + k)) * alpha
			var c := sparks[k]
			glow.draw_line(c - Vector2(s, 0), c + Vector2(s, 0), Color(1, 0.95, 0.6, alpha), 4.0, true)
			glow.draw_line(c - Vector2(0, s), c + Vector2(0, s), Color(1, 0.95, 0.6, alpha), 4.0, true))
	var tween := glow.create_tween()
	tween.tween_method(func(t: float) -> void:
		glow.set_meta("t", t)
		glow.queue_redraw(), 0.0, 1.0, 0.6)
	tween.tween_callback(glow.queue_free)
	# Uçan resim
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(canvas.thumbnail())
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.position = rect.position
	picture.size = rect.size
	picture.pivot_offset = rect.size * 0.5
	add_child(picture)
	var target := toolbar.save_button.global_position + toolbar.save_button.size * 0.5 - rect.size * 0.5
	var fly := picture.create_tween()
	fly.tween_interval(0.45)
	fly.set_parallel(true)
	fly.tween_property(picture, "position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.tween_property(picture, "scale", Vector2.ONE * 0.06, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.tween_property(picture, "rotation", 0.5, 0.5)
	fly.set_parallel(false)
	fly.tween_callback(func() -> void:
		picture.queue_free()
		toolbar.save_button.bounce())
