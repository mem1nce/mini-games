class_name ColoringHome
extends Control
# Giriş ekranı: iki büyük düğme, yazı yok. Sol: yeni resim (sayfa seçimine), sağ: galerim.
# Sol üstte basılı tutulan geri düğmesi ana menüye döner.

const BackButton := preload("res://ortak/basili_geri_dugmesi.gd")
const G := "res://oyunlar/boyama_kitabi/gorseller/"
const BG_TOP := Color("fdf1ff")
const BG_BOTTOM := Color("e4f1ff")
const DOT_COLORS := [Color("ff9aa8"), Color("ffd26b"), Color("9fe39a"), Color("8fd0ff"), Color("c9a7ff")]

var game: Node
var back: Control
var new_button: ColoringIconButton
var gallery_button: ColoringIconButton
var _owners := {}
var _time: float = 0.0
var _dots: Array[Vector3] = []        # arka plandaki renkli noktalar: x, y (0..1), yarıçap


func setup(owner_game: Node) -> void:
	game = owner_game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	back = BackButton.new()
	back.size = Vector2(96, 96)
	back.completed.connect(func() -> void: game.to_menu())
	add_child(back)
	new_button = _big_button("yeni_resim", Color("ff7a9a"))
	gallery_button = _big_button("galerim", Color("3e8eeb"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		_dots.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(6.0, 16.0)))
	resized.connect(_layout)
	_layout()


func _big_button(icon: String, accent: Color) -> ColoringIconButton:
	var button := ColoringIconButton.new()
	button.icon = load(G + icon + ".svg")
	button.icon_scale = 0.8
	button.accent = accent
	button.size = Vector2(270, 270)
	add_child(button)
	return button


func _layout() -> void:
	back.position = Vector2(40, 14)
	var center := size * 0.5 + Vector2(0, 20)
	var gap := minf(150.0, size.x * 0.1)
	new_button.position = center - Vector2(new_button.size.x + gap * 0.5, new_button.size.y * 0.5)
	gallery_button.position = center + Vector2(gap * 0.5, -gallery_button.size.y * 0.5)
	for button in [new_button, gallery_button]:
		button.pivot_offset = button.size * 0.5
		button.set_meta("base_y", button.position.y)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	# Düğmeler hafifçe süzülür
	new_button.position.y = new_button.get_meta("base_y", new_button.position.y) + sin(_time * 1.8) * 6.0
	gallery_button.position.y = gallery_button.get_meta("base_y", gallery_button.position.y) + sin(_time * 1.8 + 1.4) * 6.0


func _draw() -> void:
	var colors := PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), colors)
	for i in _dots.size():
		var dot := _dots[i]
		var color: Color = DOT_COLORS[i % DOT_COLORS.size()]
		color.a = 0.45
		draw_circle(Vector2(dot.x * size.x, dot.y * size.y), dot.z, color)


func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var owner: Control = null
			for control: Control in [back, new_button, gallery_button]:
				if control.get_global_rect().grow(6.0).has_point(event.position):
					owner = control
			if owner:
				_owners[event.index] = owner
				owner.press()
		elif _owners.has(event.index):
			var owner: Control = _owners[event.index]
			_owners.erase(event.index)
			owner.release()
			if owner == back or not owner.get_global_rect().grow(6.0).has_point(event.position):
				return
			game.sounds.play("tik")
			if owner == new_button:
				game.show_picker()
			else:
				game.show_gallery()
