extends SceneTree
# Kule Yapma ekran görüntüsü testi (pencereli). Proje kökünden (dikey oyun; pencere 450x800 = 720x1280 oranı):
#   godot --path . --fixed-fps 60 --resolution 450x800 -s res://oyunlar/kule_yapma/testler/ekran_testi.gd -- <klasör>
# Giriş, sallanan kat, oturma, mükemmel, ıska, kutlama, bölüm sonu paneli, apartman görünümü (pencere işi), galeri ve
# 20 katlık bölümde yükseklik manzaralarını <klasör> içine kaydeder. user://kule_yapma.cfg yedeklenir, geri yazılır.

const Kayit := preload("res://oyunlar/kule_yapma/kayit.gd")

var out := ""
var game: Node
var _yedek: PackedByteArray
var _yedek_var := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_yedek_var = FileAccess.file_exists(Kayit.PATH)
	if _yedek_var:
		_yedek = FileAccess.get_file_as_bytes(Kayit.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	root.get_node("SahneGecis").visible = false
	game = load("res://oyunlar/kule_yapma/kule_yapma.tscn").instantiate()
	root.add_child(game)
	await frames(90)
	await shot("k01_giris")
	tap(game._oynat.get_global_rect().get_center())
	await frames(70)
	await shot("k02_sallanan")
	await tam_ortada_birak()
	await frames(8)
	await shot("k03_mukemmel")
	await frames(60)
	await shot("k04_oturdu")
	# Bilerek ıska: en uçtayken bırak
	await bekle(func() -> bool: return game.vinc.hazir, 300)
	await bekle(func() -> bool: return absf(game.vinc.asili.global_position.x - 360.0) > 95.0, 400)
	tap(Vector2(360, 900))
	await frames(40)
	await shot("k05_iska")
	await frames(60)
	while game.durum == game.Durum.OYUN:
		await tam_ortada_birak()
		await frames(30)
	await frames(60)
	await shot("k06_kutlama")
	await bekle(func() -> bool: return game.durum == game.Durum.SONU, 400)
	await frames(30)
	await shot("k07_bolum_sonu")
	tap(game._sonu_apartman.get_global_rect().get_center())
	await frames(60)
	await shot("k08_apartman")
	var blok: Node2D = game._apartman._bloklar[2]
	tap(blok.to_global(blok._pencereler[0]))
	await frames(30)
	await shot("k09_pencere_isi")
	tap(game._apartman._kapat.get_global_rect().get_center())
	await frames(30)
	# 20 katlık bölüm: yükseklik manzaraları
	game.kayit.bolum = 11
	game._sonu.visible = false
	game.durum = game.Durum.GIRIS
	game._bolumu_hazirla()
	game._oyunu_baslat()
	for i in 20:
		await tam_ortada_birak()
		await frames(20)
		if i in [5, 9, 13, 17]:
			await frames(40)
			await shot("m%02d_kat" % (i + 1))
	await frames(90)
	await shot("m20_kutlama")
	await bekle(func() -> bool: return game.durum == game.Durum.SONU, 400)
	game._geri_basildi()
	await frames(30)
	tap(game._galeri_dugme.get_global_rect().get_center())
	await frames(40)
	await shot("k10_galeri")
	game.queue_free()
	await process_frame
	if _yedek_var:
		var f := FileAccess.open(Kayit.PATH, FileAccess.WRITE)
		f.store_buffer(_yedek)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	quit()


# Kat tam ortadan geçerken bırakır, oturmasını bekler
func tam_ortada_birak() -> void:
	await bekle(func() -> bool: return game.vinc.hazir, 300)
	await bekle(func() -> bool: return game.vinc.asili != null and absf(game.vinc.asili.global_position.x - game.kule.tepe().x) < 5.0, 600)
	tap(Vector2(360, 900))
	await bekle(func() -> bool: return game.vinc.hazir or game.durum != game.Durum.OYUN, 300)


func bekle(kosul: Callable, en_fazla: int) -> void:
	for i in en_fazla:
		if kosul.call():
			return
		await process_frame


func tap(pos: Vector2) -> void:
	for basili in [true, false]:
		var ev := InputEventScreenTouch.new()
		ev.position = pos
		ev.pressed = basili
		root.push_input(ev, true)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("çekildi: ", name)
