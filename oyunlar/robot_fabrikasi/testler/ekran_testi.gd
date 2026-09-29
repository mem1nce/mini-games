extends SceneTree
# Robot Fabrikası ekran görüntüsü testi (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://oyunlar/robot_fabrikasi/testler/ekran_testi.gd -- <klasör>
# Bölüm 1 (bant, kutular, yardımcı), parça sürükleme, yanlış kutu (yardımcı doğru kutuyu gösterir), montaj,
# uyanan robot ve kutlama, galeri, duraklatma, ipucu ve başka bölümlerin tabelaları (şekil, boyut, renk+şekil,
# sayma) görüntülerini <klasör> içine PNG olarak kaydeder. Sonunda user://robot_fabrikasi.cfg silinir.

const Yonetici := preload("res://oyunlar/robot_fabrikasi/bolum_yoneticisi.gd")
const Robot := preload("res://oyunlar/robot_fabrikasi/robot.gd")

var out := ""
var game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	_save(0, {})
	await _open()
	await shot("r1_bolum1")
	var part := _belt_part()
	var right: int = game.manager.box_for(part.data)
	var wrong: int = (right + 1) % game.boxes.size()
	var from: Vector2 = part.global_position
	var to: Vector2 = game.boxes[wrong].global_position + Vector2(0, 120)
	touch(from, true)
	for k in 20:
		drag(from.lerp(to, k / 19.0))
		await process_frame
	await shot("r2_surukle")
	touch(to, false)
	await frames(30)
	await shot("r3_yanlis")
	await frames(60)
	# Bölümü bitir: kalan parçaları doğru kutulara koy
	while not game._level_done:
		part = _belt_part()
		if part == null:
			await frames(10)
			continue
		right = game.manager.box_for(part.data)
		from = part.global_position
		to = game.boxes[right].global_position + Vector2(0, 120)
		touch(from, true)
		await frames(3)
		drag(to)
		await frames(2)
		touch(to, false)
		await frames(30)
	await frames(80)
	await shot("r4_montaj")
	await frames(90)
	await shot("r5_uyandi")
	await frames(50)
	await shot("r6_kutlama")
	await frames(40)
	await shot("r6b_kutlama")
	await frames(150)
	await shot("r7_ucus")
	while game._montage.running or game._level_done:
		await process_frame
	await frames(60)
	await shot("r7b_sonraki")
	# Galeri: birkaç robot yapılmış
	var gallery := {}
	for id in ["tekerlekli", "yayli", "pervaneli", "uzun_boyunlu", "ucan", "orumcek", "roketli", "dev"]:
		gallery[id] = {"body": {"color": ["kirmizi", "mavi", "sari", "yesil"].pick_random(), "shape": ["daire", "kare", "ucgen", "yildiz"].pick_random()},
			"head": {"color": ["kirmizi", "mavi", "sari", "yesil"].pick_random(), "shape": ["daire", "kare", "ucgen", "yildiz"].pick_random()},
			"arm": "mavi", "antenna": "sari", "wheel": "kirmizi"}
	game.manager.gallery = gallery
	var icon: Vector2 = game._gallery_icon.get_global_rect().get_center()
	touch(icon, true)
	touch(icon, false)
	await frames(50)
	await shot("r8_galeri")
	touch(Vector2(20, 700), true)
	touch(Vector2(20, 700), false)
	await frames(30)
	var pause: Vector2 = game._pause.get_global_rect().get_center()
	touch(pause, true)
	touch(pause, false)
	await frames(30)
	await shot("r9_duraklat")
	var resume: Vector2 = game._resume.get_global_rect().get_center()
	touch(resume, true)
	touch(resume, false)
	# İpucu: hamle yapmadan bekle
	await frames(int(game.hint_delay * 60.0) + 40)
	await shot("r10_ipucu")
	await frames(80)
	await shot("r11_ipucu_kutu")
	# Diğer bölümlerin tabelaları
	for level in [3, 6, 9, 12, 13, 14]:
		game.queue_free()
		await process_frame
		_save(level, {})
		await _open()
		await shot("b%02d" % (level + 1))
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Yonetici.PATH))
	quit()


func _open() -> void:
	game = load("res://oyunlar/robot_fabrikasi/robot_fabrikasi.tscn").instantiate()
	root.add_child(game)
	await frames(300)


func _save(level: int, gallery: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("ilerleme", "bolum", level)
	for id in gallery:
		config.set_value("galeri", id, gallery[id])
	config.save(Yonetici.PATH)


func _belt_part() -> Node2D:
	var best: Node2D = null
	for part in game._belt.parts:
		if part.on_belt and part.visible and part.position.x > 200.0 and part.position.x < 1000.0:
			if best == null or part.position.x > best.position.x:
				best = part
	return best


func touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func drag(pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.position = pos
	root.push_input(ev, true)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("çekildi: ", name)
