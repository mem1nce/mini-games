extends SceneTree
# Ana menü ekran görüntüleri (pencereli). Proje kökünden:
#   godot --path . --fixed-fps 60 --resolution 1280x720 -s res://ana_menu/testler/ekran_testi.gd -- <klasör> [GxY]
# İsteğe bağlı GxY (ör. 720x1600, 960x1280) farklı ekran oranı dener. Açılış, basılı kart, kaydırılmış liste,
# alt uçta esneme ve her sekmenin görüntüsünü <klasör> içine kaydeder. user://ana_menu.cfg'ye dokunmaz.

const MENU := "res://ana_menu/ana_menu.tscn"

var out := ""
var menu: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	var on_ek := ""
	if args.size() > 1:
		var p := args[1].split("x")
		root.size = Vector2i(int(p[0]), int(p[1]))
		on_ek = args[1] + "_"
	root.get_node("SahneGecis").visible = false
	menu = load(MENU).instantiate()
	root.add_child(menu)
	await frames(8)
	await shot(on_ek + "m0_acilis_basi")
	await frames(90)
	await shot(on_ek + "m1_acilis")
	# Bir karta bas (bırakmadan)
	var kart: Control = menu._gorunen[1]
	touch(kart.get_global_rect().get_center(), true)
	await frames(10)
	await shot(on_ek + "m2_basili")
	# Kaydırmaya dönüşünce kart eski boyuna döner
	await drag_steps(kart.get_global_rect().get_center(), Vector2(0, -420), 12)
	touch(kart.get_global_rect().get_center() + Vector2(0, -420), false)
	await frames(60)
	await shot(on_ek + "m3_kaydi")
	# Alt uca at, esnemeyi yakala
	menu._hiz = 6000.0
	await frames(30)
	await shot(on_ek + "m4_alt_esneme")
	await frames(90)
	await shot(on_ek + "m5_alt")
	for i in range(1, menu._sekmeler.size()):
		var sekme: Control = menu._sekmeler[i]
		var yer := sekme.get_global_rect().get_center()
		touch(yer, true)
		touch(yer, false)
		await frames(60)
		await shot(on_ek + "m6_sekme_%s" % sekme.kategori["id"])
	quit()


func touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func drag_steps(from: Vector2, move: Vector2, steps: int) -> void:
	for i in range(1, steps + 1):
		var ev := InputEventScreenDrag.new()
		ev.position = from + move * i / steps
		root.push_input(ev, true)
		await process_frame


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
