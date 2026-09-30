class_name ColoringCanvas
extends Control
# Boyama tuvali: sayfanın katmanları, yakınlaştırma/kaydırma, araçlara dokunma, geri alma, kayıt görüntüleri.
#
# Katmanlar (alttan üste), hepsi _page düğümünde (tuval pikseli biriminde, ölçeklenerek gösterilir):
#   1. Bölge boyası: bölge haritası + bolge.gdshader (renk = palet dokusunda bölgenin pikseli). Bir bölgeyi
#      boyamak palette tek piksel değiştirmektir; kenarlar çizgilerin altında kaldığı için boşluk kalmaz.
#   2. Fırça/damga katmanı: _live SubViewport'unun dokusu. İçinde önce kalıcı katman (_base SubViewport'u,
#      geri alınamayacak kadar eski çizimler), sonra geri alınabilir her işlemin kendi düğümü. Görüntü sadece
#      bir şey değişince yeniden çizilir (her karede değil).
#   3. Çizgiler (lines.png, mipmap'li): her zaman en üstte.
# Viewport'lar önceden çarpılmış alfa üretir; fırça katmanı PREMULT_ALPHA karışımıyla gösterilir.
#
# Dokunma: ekran her parmağı (index) ayrı verir. Tek parmak her zaman seçili aracı kullanır; ikinci parmak
# değince iki parmak hareketi (yakınlaştırma + kaydırma) başlar ve ilk parmağın yeni başlamış/kısa işi iptal
# edilir (avuç içi koruması). Fare tekerleği de yakınlaştırır.

signal changed                        # yeni işlem, geri alma, temizleme
signal zoom_changed(zoomed: bool)
signal sound(name: String, pitch: float)

const Settings := preload("res://oyunlar/boyama_kitabi/ayarlar.gd")
const REGION_SHADER := preload("res://oyunlar/boyama_kitabi/tuval/bolge.gdshader")
const ClearLayer := preload("res://oyunlar/boyama_kitabi/tuval/temizle_katmani.gd")
const PageList := preload("res://oyunlar/boyama_kitabi/sayfalar/sayfa_listesi.gd")
const PAGES_DIR := "res://oyunlar/boyama_kitabi/sayfalar/png/"

const MAX_ZOOM := 5.0
const MARGIN := 10.0
const FILL_TIME := 0.25               # kova dalgasının süresi (sn)
const PALM_TIME := 0.35               # ikinci parmak bu kadar içinde gelirse ilk parmağın işi iptal
const LINE_ALPHA := 0.5               # çizgi pikseli sayılan örtme
const PAPER := Settings.PAPER

var page_id: String = ""
var colors := PackedColorArray()      # bölge renkleri (0 = kağıt)
var canvas_size := Vector2i(2048, 1536)
var tool: ColoringTool
var history := ColoringUndoStack.new()
var dirty: bool = false               # son kayıttan beri değişti mi
var loop_level: float = 0.0           # fırça sesi için: parmağın hızı (0..1), her karede söner

var _page: Node2D
var _regions: Sprite2D
var _brush: Sprite2D
var _lines: Sprite2D
var _effects: Node2D
var _region_material: ShaderMaterial
var _palette_image: Image
var _palette_texture: ImageTexture
var _region_image: Image              # CPU'da bölge haritası (dokunulan bölgeyi bulmak için)
var _line_mask: Image                 # CPU'da çizgi örtmesi (yarı çözünürlük)
var _region_boxes: Array[Rect2] = []  # her bölgenin sınır kutusu (kova dalgasının boyu)
var _base: SubViewport                # kalıcı fırça katmanı (hiç silinmez, üstüne işlenir)
var _live: SubViewport                # gösterilen fırça katmanı: kalıcı katman + geri alınabilir işlemler
var _ops: Node2D
var _snapshot: SubViewport            # galeri küçük resmi
var _fit_scale: float = 1.0
var _zoom: float = 1.0
var _offset := Vector2.ZERO
var _fill_tween: Tween
var _view_tween: Tween
var _redraw: bool = false
var _redraw_until: int = 0
var _brush_used: bool = false         # fırça katmanında hiç bir şey oldu mu (boşsa kaydedilmez)

# Dokunma
var _fingers := {}                    # index -> konum (ekran)
var _tool_finger: int = -1
var _tool_started: int = 0
var _gesture := false
var _gesture_start := {}
var _blocked := {}                    # iki parmak hareketinden kalan, bırakılana kadar çizmeyen parmaklar


# --- Kurulum ---

## page: sayfa kimliği; saved_colors boşsa sayfa beyaz başlar; brush: kaydedilmiş fırça katmanı (ya da null)
func setup(page: String, saved_colors: PackedColorArray, brush: Image) -> void:
	page_id = page
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var region_texture: Texture2D = load(PAGES_DIR + page + "_bolge.png")
	var lines_texture: Texture2D = load(PAGES_DIR + page + "_cizgi.png")
	canvas_size = region_texture.get_size()
	_region_image = region_texture.get_image()
	if _region_image.is_compressed():
		_region_image.decompress()
	_region_image.convert(Image.FORMAT_L8)
	_line_mask = lines_texture.get_image()
	if _line_mask.is_compressed():
		_line_mask.decompress()
	_line_mask.clear_mipmaps()
	_line_mask.resize(canvas_size.x / 2, canvas_size.y / 2, Image.INTERPOLATE_BILINEAR)
	var count := _scan_regions()
	for entry in PageList.PAGES:
		if entry["id"] == page:
			count = maxi(count, entry["regions"])
	while _region_boxes.size() < count:
		_region_boxes.append(Rect2(Vector2.ZERO, canvas_size))
	colors = saved_colors.duplicate() if saved_colors.size() == count else _blank_colors(count)
	if saved_colors.size() > 0 and saved_colors.size() != count:
		push_warning("Boyama: %s kaydındaki renk sayısı sayfayla tutmuyor; sayfa beyaz açıldı" % page)
	_palette_image = Image.create(256, 1, false, Image.FORMAT_RGBA8)
	for i in colors.size():
		_palette_image.set_pixel(i, 0, colors[i])
	_palette_texture = ImageTexture.create_from_image(_palette_image)

	_build_brush_layer(brush)
	_region_material = ShaderMaterial.new()
	_region_material.shader = REGION_SHADER
	_region_material.set_shader_parameter("palette", _palette_texture)
	_region_material.set_shader_parameter("tex_size", Vector2(canvas_size))

	_page = Node2D.new()
	add_child(_page)
	_regions = _sprite(region_texture, TEXTURE_FILTER_NEAREST)
	_regions.material = _region_material
	_brush = _sprite(_live.get_texture(), TEXTURE_FILTER_LINEAR)
	_brush.material = _premultiplied()
	_lines = _sprite(lines_texture, TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
	for sprite in [_regions, _brush, _lines]:
		_page.add_child(sprite)
	_effects = Node2D.new()
	_page.add_child(_effects)
	_build_snapshot(region_texture, lines_texture)
	# Kalıcı katman ilk karede yüklenen çizimi alır; gösterilen katman birkaç kare onu izlesin
	keep_redrawing(0.25)
	resized.connect(_fit)
	_fit()


func _sprite(texture: Texture2D, filter: TextureFilter) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = filter
	return sprite


func _premultiplied() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return mat


func _viewport(size_px: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size_px
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	return viewport


func _build_brush_layer(brush: Image) -> void:
	_base = _viewport(canvas_size)
	_base.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	if brush != null and not brush.is_empty():
		var saved := _sprite(ImageTexture.create_from_image(brush), TEXTURE_FILTER_NEAREST)
		saved.material = _premultiplied()
		_base.add_child(saved)
		_brush_used = true
		_free_after_draw(saved)
	_live = _viewport(canvas_size)
	var base_sprite := _sprite(_base.get_texture(), TEXTURE_FILTER_NEAREST)
	base_sprite.material = _premultiplied()
	_live.add_child(base_sprite)
	_ops = Node2D.new()
	_live.add_child(_ops)


func _build_snapshot(region_texture: Texture2D, lines_texture: Texture2D) -> void:
	var width: int = Settings.ART_THUMB_WIDTH
	var scale_factor := float(width) / canvas_size.x
	_snapshot = _viewport(Vector2i(width, roundi(canvas_size.y * scale_factor)))
	_snapshot.transparent_bg = false
	_snapshot.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var holder := Node2D.new()
	holder.scale = Vector2(scale_factor, scale_factor)
	_snapshot.add_child(holder)
	var regions := _sprite(region_texture, TEXTURE_FILTER_NEAREST)
	regions.material = _region_material
	var brush := _sprite(_live.get_texture(), TEXTURE_FILTER_LINEAR)
	brush.material = _premultiplied()
	for sprite in [regions, brush, _sprite(lines_texture, TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)]:
		holder.add_child(sprite)


# Bölge sayısı (en büyük numara + 1) ve her bölgenin sınır kutusu (kova dalgasının boyu için).
# Hız için 4 pikselde bir örneklenir: derleyici her bölgenin görünür alanının bundan çok büyük olduğunu denetler.
func _scan_regions() -> int:
	const STEP := 4
	var data := _region_image.get_data()
	var mins := PackedInt32Array()
	var maxs := PackedInt32Array()
	mins.resize(512)
	maxs.resize(512)
	mins.fill(1 << 30)
	maxs.fill(-1)
	var highest := 0
	for y in range(0, canvas_size.y, STEP):
		var row := y * canvas_size.x
		for x in range(0, canvas_size.x, STEP):
			var id := data[row + x]
			if x < mins[id * 2]:
				mins[id * 2] = x
			if x > maxs[id * 2]:
				maxs[id * 2] = x
			if y < mins[id * 2 + 1]:
				mins[id * 2 + 1] = y
			maxs[id * 2 + 1] = y
			if id > highest:
				highest = id
	_region_boxes.clear()
	for id in highest + 1:
		if maxs[id * 2] < 0:
			_region_boxes.append(Rect2(Vector2.ZERO, canvas_size))
		else:
			var start := Vector2(mins[id * 2], mins[id * 2 + 1]) - Vector2(STEP, STEP)
			_region_boxes.append(Rect2(start, Vector2(maxs[id * 2], maxs[id * 2 + 1]) - start + Vector2(STEP * 2, STEP * 2)))
	return highest + 1


func _blank_colors(count: int) -> PackedColorArray:
	var result := PackedColorArray()
	result.resize(count)
	result.fill(PAPER)
	return result


func paper_color() -> Color:
	return PAPER


# --- Görünüm: sığdırma, yakınlaştırma, kaydırma ---

func _fit() -> void:
	if _page == null or size.x <= 0.0:
		return
	var available := size - Vector2(MARGIN, MARGIN) * 2.0
	_fit_scale = minf(available.x / canvas_size.x, available.y / canvas_size.y)
	_apply_view(_zoom, _offset if _zoom > 1.0 else _centered(1.0))


func view_scale() -> float:
	return _fit_scale * _zoom


func is_zoomed() -> bool:
	return _zoom > 1.01


func page_rect() -> Rect2:
	return Rect2(_offset, Vector2(canvas_size) * view_scale())


func _centered(zoom: float) -> Vector2:
	return (size - Vector2(canvas_size) * _fit_scale * zoom) * 0.5


func _apply_view(zoom: float, offset: Vector2) -> void:
	var was_zoomed := is_zoomed()
	_zoom = clampf(zoom, 1.0, MAX_ZOOM)
	var page_size := Vector2(canvas_size) * view_scale()
	# Sayfa görünen alandan küçükse ortala, büyükse kenarları dışarıda boşluk bırakmasın
	for axis in 2:
		if page_size[axis] <= size[axis] - MARGIN * 2.0:
			offset[axis] = (size[axis] - page_size[axis]) * 0.5
		else:
			offset[axis] = clampf(offset[axis], size[axis] - MARGIN - page_size[axis], MARGIN)
	_offset = offset
	_page.position = _offset
	_page.scale = Vector2.ONE * view_scale()
	queue_redraw()
	if was_zoomed != is_zoomed():
		zoom_changed.emit(is_zoomed())


## Ekrandaki noktayı (tuvalin yerel koordinatı) sabit tutarak yakınlaştırır
func zoom_at(local_point: Vector2, factor: float) -> void:
	var page_point := (local_point - _offset) / view_scale()
	var zoom := clampf(_zoom * factor, 1.0, MAX_ZOOM)
	_apply_view(zoom, local_point - page_point * _fit_scale * zoom)


func reset_view() -> void:
	if _view_tween:
		_view_tween.kill()
	var start_zoom := _zoom
	var start_offset := _offset
	var target := _centered(1.0)
	_view_tween = create_tween()
	_view_tween.tween_method(func(t: float) -> void:
		_apply_view(lerpf(start_zoom, 1.0, t), start_offset.lerp(target, t)), 0.0, 1.0, 0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func to_page(screen_pos: Vector2) -> Vector2:
	return (screen_pos - global_position - _offset) / view_scale()


func _draw() -> void:
	if _page == null:
		return
	# Sayfanın altında yumuşak gölge ve kağıt kenarı
	var rect := page_rect()
	draw_rect(Rect2(rect.position + Vector2(0, 8), rect.size).grow(4), Color(0.23, 0.18, 0.42, 0.12))
	draw_rect(rect.grow(3), Color(0.23, 0.18, 0.42, 0.18))


# --- Dokunma (ekran parmakları buraya yönlendirir; konumlar ekran koordinatı) ---

func touch_down(index: int, pos: Vector2) -> void:
	_fingers[index] = pos
	if _gesture:
		return
	if _fingers.size() == 1:
		_tool_finger = index
		_tool_started = Time.get_ticks_msec()
		if tool:
			tool.begin(to_page(pos))
	elif _fingers.size() == 2:
		# İkinci parmak: iki parmak hareketi (kalkmamış eski parmak da katılabilir)
		_end_tool_for_gesture()
		_blocked.clear()
		_start_gesture()


func touch_move(index: int, pos: Vector2) -> void:
	if not _fingers.has(index):
		return
	_fingers[index] = pos
	if _gesture:
		_update_gesture()
	elif index == _tool_finger and tool:
		tool.move(to_page(pos))


func touch_up(index: int, pos: Vector2) -> void:
	if not _fingers.has(index):
		return
	_fingers[index] = pos
	if index == _tool_finger:
		_tool_finger = -1
		if tool:
			tool.end()
	_fingers.erase(index)
	_blocked.erase(index)
	if _gesture and _gesture_start.has(index):
		_gesture = false
		# Kalan parmak kalkana kadar çizmesin
		for other in _fingers:
			_blocked[other] = true


## Sistem iptali ya da ekran değişimi: yarım kalan işi bitir, parmakları unut
func release_all() -> void:
	if _tool_finger != -1 and tool:
		tool.end()
	_tool_finger = -1
	_fingers.clear()
	_blocked.clear()
	_gesture = false


func has_fingers() -> bool:
	return not _fingers.is_empty()


## Seçili araç şu an bir parmakla kullanılıyor mu (fırça sesi için)
func tool_active() -> bool:
	return _tool_finger != -1


func _end_tool_for_gesture() -> void:
	if _tool_finger == -1 or tool == null:
		return
	var recent := Time.get_ticks_msec() - _tool_started < PALM_TIME * 1000.0
	if recent or tool.is_small():
		tool.cancel()
	else:
		tool.end()
	_tool_finger = -1


func _start_gesture() -> void:
	_gesture = true
	var keys := _fingers.keys()
	var a: Vector2 = _fingers[keys[0]] - global_position
	var b: Vector2 = _fingers[keys[1]] - global_position
	_gesture_start = {keys[0]: true, keys[1]: true}
	_gesture_start["distance"] = maxf(a.distance_to(b), 1.0)
	_gesture_start["zoom"] = _zoom
	_gesture_start["page_point"] = ((a + b) * 0.5 - _offset) / view_scale()
	if _view_tween:
		_view_tween.kill()


func _update_gesture() -> void:
	var points: Array[Vector2] = []
	for key in _fingers:
		if _gesture_start.has(key):
			points.append(_fingers[key] - global_position)
	if points.size() < 2:
		return
	var mid := (points[0] + points[1]) * 0.5
	var zoom: float = _gesture_start["zoom"] * points[0].distance_to(points[1]) / _gesture_start["distance"]
	zoom = clampf(zoom, 1.0, MAX_ZOOM)
	_apply_view(zoom, mid - _gesture_start["page_point"] * _fit_scale * zoom)


# --- Araçların kullandığı işlemler ---

## Dokunulan noktadaki bölge. Nokta çizginin üstündeyse en yakın çizgisiz pikselin bölgesi.
func region_at(page_pos: Vector2) -> int:
	var x := clampi(int(page_pos.x), 0, canvas_size.x - 1)
	var y := clampi(int(page_pos.y), 0, canvas_size.y - 1)
	if not _on_line(x, y):
		return _region_id(x, y)
	for radius in range(3, 72, 3):
		var steps := maxi(12, radius)
		for k in steps:
			var angle := TAU * k / steps
			var px := x + roundi(cos(angle) * radius)
			var py := y + roundi(sin(angle) * radius)
			if px >= 0 and py >= 0 and px < canvas_size.x and py < canvas_size.y and not _on_line(px, py):
				return _region_id(px, py)
	return _region_id(x, y)


func _region_id(x: int, y: int) -> int:
	return mini(roundi(_region_image.get_pixel(x, y).r * 255.0), colors.size() - 1)


func _on_line(x: int, y: int) -> bool:
	return _line_mask.get_pixel(x / 2, y / 2).a >= LINE_ALPHA


func set_region_color(region: int, color: Color, from: Vector2, animate: bool) -> void:
	var old := colors[region]
	colors[region] = color
	_palette_image.set_pixel(region, 0, color)
	_palette_texture.update(_palette_image)
	if _fill_tween:
		_fill_tween.kill()
	if not animate:
		_region_material.set_shader_parameter("anim_region", -1)
		return
	var box := _region_boxes[region] if region < _region_boxes.size() else Rect2(Vector2.ZERO, canvas_size)
	var reach := 0.0
	for corner in [box.position, box.position + Vector2(box.size.x, 0), box.position + Vector2(0, box.size.y), box.end]:
		reach = maxf(reach, from.distance_to(corner))
	_region_material.set_shader_parameter("anim_region", region)
	_region_material.set_shader_parameter("anim_center", from)
	_region_material.set_shader_parameter("anim_old_color", old)
	_fill_tween = create_tween()
	_fill_tween.tween_method(func(r: float) -> void: _region_material.set_shader_parameter("anim_radius", r),
		0.0, reach + 20.0, FILL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fill_tween.tween_callback(func() -> void: _region_material.set_shader_parameter("anim_region", -1))


func add_layer_node(node: Node2D) -> void:
	_ops.add_child(node)
	_brush_used = true
	request_redraw()


func remove_layer_node(node: Node2D) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.queue_free()
	request_redraw()


func request_redraw() -> void:
	_redraw = true


## Animasyonlu bir katman (damga) için bir süre her karede yeniden çiz
func keep_redrawing(seconds: float) -> void:
	_redraw_until = maxi(_redraw_until, Time.get_ticks_msec() + int(seconds * 1000.0))


func stroke_moved(page_distance: float) -> void:
	loop_level = minf(1.0, loop_level + page_distance * view_scale() / 60.0)


func play_sound(name: String, pitch: float = 1.0) -> void:
	sound.emit(name, pitch)


## Dokunulan yerde küçük bir ışıltı (zaten aynı renkteki bölgeye kova ile dokununca)
func sparkle(page_pos: Vector2) -> void:
	var ring := Node2D.new()
	ring.position = page_pos
	var unit := 1.0 / maxf(view_scale(), 0.01)     # bir ekran pikseli, tuval pikseli cinsinden
	ring.draw.connect(func() -> void:
		var t: float = ring.get_meta("t", 0.0)
		ring.draw_arc(Vector2.ZERO, (16.0 + 44.0 * t) * unit, 0.0, TAU, 40,
			Color(1.0, 0.8, 0.25, 0.95 * (1.0 - t)), 7.0 * unit, true))
	_effects.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_method(func(t: float) -> void:
		ring.set_meta("t", t)
		ring.queue_redraw(), 0.0, 1.0, 0.35)
	tween.tween_callback(ring.queue_free)


## İşi geri alma yığınına ekler; sınırdan düşen eski işleri kalıcı katmana işler
func commit(entry: Dictionary) -> void:
	for old in history.push(entry):
		_bake(old)
	dirty = true
	changed.emit()


func undo() -> bool:
	var entry := history.pop()
	if entry.is_empty():
		return false
	_revert(entry)
	dirty = true
	changed.emit()
	return true


func clear_all() -> void:
	var entry := {"kind": "clear", "colors": colors.duplicate()}
	var node := ClearLayer.new()
	node.size = Vector2(canvas_size)
	add_layer_node(node)
	entry["node"] = node
	for i in colors.size():
		colors[i] = PAPER
		_palette_image.set_pixel(i, 0, PAPER)
	_palette_texture.update(_palette_image)
	_region_material.set_shader_parameter("anim_region", -1)
	commit(entry)


func _revert(entry: Dictionary) -> void:
	match entry["kind"]:
		"region":
			set_region_color(entry["region"], entry["before"], entry["at"], true)
		"layer":
			remove_layer_node(entry["node"])
		"clear":
			remove_layer_node(entry["node"])
			var saved: PackedColorArray = entry["colors"]
			for i in saved.size():
				colors[i] = saved[i]
				_palette_image.set_pixel(i, 0, saved[i])
			_palette_texture.update(_palette_image)
		"group":
			var items: Array = entry["items"]
			for i in range(items.size() - 1, -1, -1):
				_revert(items[i])


# Geri alınamayacak kadar eski işin düğümünü kalıcı katmana (hiç silinmeyen _base) bir kez çizer.
# Görüntü kırpışmasın diye kopya kalıcı katmana çizilirken asıl düğüm bir kare daha yerinde kalır.
func _bake(entry: Dictionary) -> void:
	if entry["kind"] == "group":
		for item in entry["items"]:
			_bake(item)
		return
	if not entry.has("node"):
		return
	var node: Node2D = entry["node"]
	var copy: Node2D = node.clone()
	_base.add_child(copy)
	_base.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	copy.queue_free()
	remove_layer_node(node)


func _free_after_draw(node: Node) -> void:
	await RenderingServer.frame_post_draw
	node.queue_free()


func _process(delta: float) -> void:
	if _live == null:
		return
	if _redraw or Time.get_ticks_msec() < _redraw_until:
		_redraw = false
		_live.render_target_update_mode = SubViewport.UPDATE_ONCE
	loop_level = maxf(0.0, loop_level - delta * 5.0)


# --- Kayıt ---

func has_brush_content() -> bool:
	return _brush_used


## Fırça katmanı (önceden çarpılmış alfa, tuval boyutunda). Son çizimin görüntüye geçmesi için önce
## await RenderingServer.frame_post_draw beklenebilir; beklenmezse son çizilmiş kare alınır.
func brush_image() -> Image:
	return _live.get_texture().get_image()


func thumbnail() -> Image:
	return _snapshot.get_texture().get_image()
