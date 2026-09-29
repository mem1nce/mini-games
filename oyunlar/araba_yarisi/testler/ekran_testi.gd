extends SceneTree
# Araba Yarışı ekran görüntüsü testi (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://oyunlar/araba_yarisi/testler/ekran_testi.gd -- <klasör> [pist no]
# Garaj, harita, geri sayım, yarış, zıplama, su birikintisi, duraklatma, bitiş ve podyumun görüntüsünü
# <klasör> içine PNG olarak kaydeder. Dokunmalar root.push_input(olay, true) ile gönderilir.

const SAVE := "user://araba_yarisi.cfg"

var out := ""
var game: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	var track := int(args[1]) - 1 if args.size() > 1 else 0
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	game = load("res://oyunlar/araba_yarisi/araba_yarisi.tscn").instantiate()
	root.add_child(game)
	await _frames(80)
	_shot("01_garaj")
	_tap(game._garage._swatches[4].get_global_rect().get_center())
	await _frames(5)
	_tap(game._garage._cards[2].get_global_rect().get_center())
	await _frames(50)
	_shot("02_garaj_secim")
	_tap(game._garage._play.get_global_rect().get_center())
	await _frames(80)
	if track > 0:
		game._unlocked = track + 1
		game._show_map()
		await _frames(60)
	_shot("03_harita")
	_tap(game._map._nodes[track].get_global_rect().get_center())
	await _frames(170)
	_shot("04_geri_sayim")
	await _frames(250)
	_shot("05_ipucu")
	_hold(true)
	await _frames(240)
	_shot("06_yaris")
	var player: Node2D = game._cars[0]
	for f in 4000:
		await process_frame
		if player.airborne and player._air_t > 0.45:
			break
	_shot("07_zipla")
	for f in 4000:
		await process_frame
		if player._slow_t > 0.4:
			break
	await _frames(4)
	_shot("08_su")
	_hold(false)
	_tap(game._hud._pause.get_global_rect().get_center())
	await _frames(30)
	_shot("09_duraklat")
	_tap(game._hud._resume.get_global_rect().get_center())
	await _frames(10)
	_hold(true)
	# Bitişe yakın bir yere ışınla
	player.s = game._track.finish_s - 2200.0
	for car in game._cars:
		if car != player:
			car.s = maxf(car.s, player.s - 300.0)
	for f in 2000:
		await process_frame
		if player.finished:
			break
	await _frames(25)
	_shot("10_bitis")
	_hold(false)
	await _frames(420)
	_shot("11_podyum")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(file_name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out, file_name])
	print("kaydedildi: ", file_name)


func _tap(pos: Vector2) -> void:
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 5
		touch.position = pos
		touch.pressed = pressed
		root.push_input(touch, true)


# Ekranın ortasına basılı tut (gaz)
func _hold(pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(700, 500)
	touch.pressed = pressed
	root.push_input(touch, true)
