extends SceneTree
# Lisanslar ekranı testi. Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://ana_menu/testler/lisans_testi.gd
# Pencereli çalıştırılıp sonuna "-- <klasör>" eklenirse ekran görüntüleri de kaydeder (--resolution 720x1280).
# Denetler: bilgi düğmesi kısa dokunuşla ve 2 sn basmayla açılmaz, 3 sn basılı tutunca açılır (ebeveyn kapısı);
# ekranda Godot lisansı, bileşen listesi, OFL ve ses kaynakları vardır; açıkken menü dokunma almaz; kaydırma,
# "tam lisans metinleri", geri düğmesi ve Escape çalışır; Escape ekran açıkken uygulamadan çıkmaz.
# Hata varsa çıkış kodu 1. user:// kayıtlarına dokunmaz.

const MENU := "res://ana_menu/ana_menu.tscn"

var failures := 0
var menu: Control
var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ""
	change_scene_to_file(MENU)
	for i in 600:
		await process_frame
		if current_scene and current_scene.scene_file_path == MENU and not root.get_node("SahneGecis").gecis_suruyor:
			break
	menu = current_scene
	await _frames(60)
	var dugme: Control = menu._bilgi_dugmesi
	var merkez := dugme.get_global_rect().get_center()
	await _shot("l0_menu")

	# Kısa dokunuş: açılmaz, ipucu yazısı belirir
	_touch(merkez, true)
	await _frames(6)
	_touch(merkez, false)
	await _frames(20)
	_expect(menu._lisanslar == null, "kısa dokunuş Lisanslar'ı açmadı")
	_expect(menu._bilgi_ipucu.modulate.a > 0.9, "kısa dokunuşta ipucu yazısı göründü")
	await _shot("l1_ipucu")

	# 2 sn basılı tutmak yetmez
	_touch(merkez, true)
	await _frames(120)
	await _shot("l2_basili")
	_touch(merkez, false)
	await _frames(40)
	_expect(menu._lisanslar == null, "2 sn basılı tutmak Lisanslar'ı açmadı")

	# 3 sn basılı tutunca açılır
	_touch(merkez, true)
	await _frames(170)
	_expect(menu._lisanslar == null, "2.8 sn'de henüz açılmadı")
	await _frames(20)
	_expect(menu._lisanslar != null, "3 sn basılı tutunca Lisanslar açıldı")
	_touch(merkez, false)
	await _frames(30)
	var ekran: Control = menu._lisanslar
	if ekran == null:
		_bitir()
		return
	await _shot("l3_lisanslar")

	var yazi := _butun_yazi(ekran)
	_expect("Godot Engine contributors" in yazi, "Godot lisans metni var")
	_expect("Permission is hereby granted" in yazi, "MIT izin metni var")
	_expect("FreeType" in yazi, "üçüncü taraf bileşen listesi var (FreeType)")
	_expect("SIL OPEN FONT LICENSE" in yazi and "Nunito Project Authors" in yazi, "yazı tipi lisansı (OFL) var")
	_expect("Kenney" in yazi and "opengameart.org" in yazi, "ses kaynakları var")

	# Ekran açıkken menü dokunma almaz (kartın olduğu yere dokunmak oyun açmaz)
	_touch(Vector2(190, 760), true)
	_touch(Vector2(190, 760), false)
	await _frames(30)
	_expect(current_scene == menu and not menu._secildi, "Lisanslar açıkken menü kartı dokunma almadı")

	# Kaydırma
	_touch(Vector2(360, 1000), true)
	await process_frame
	for i in range(1, 11):
		var ev := InputEventScreenDrag.new()
		ev.position = Vector2(360, 1000 - i * 60)
		root.push_input(ev, true)
		await process_frame
	_touch(Vector2(360, 400), false)
	await _frames(30)
	_expect(ekran._konum > 400.0, "liste parmakla kaydı (%.0f)" % ekran._konum)
	_expect(ekran._en_fazla() > 2000.0, "içerik ekrandan uzun (%.0f)" % ekran._en_fazla())
	await _shot("l4_kaydi")

	# En alta in, "tam lisans metinleri" düğmesine dokun
	ekran._hiz = 0.0
	ekran._konum = ekran._en_fazla()
	await _frames(5)
	await _shot("l5_alt")
	var once: int = ekran._icerik.get_child_count()
	var uzunluk: float = ekran._en_fazla()
	_tap(ekran._tam_metin_dugmesi.get_global_rect().get_center())
	await _frames(20)
	_expect(ekran._icerik.get_child_count() > once + 6, "tam lisans metinleri eklendi (%d → %d)" % [once, ekran._icerik.get_child_count()])
	_expect(ekran._en_fazla() > uzunluk + 2000.0, "içerik uzadı (%.0f → %.0f)" % [uzunluk, ekran._en_fazla()])
	_expect("Apache License" in _butun_yazi(ekran), "Apache lisans metni var")
	await _shot("l6_tam_metin")

	# Escape ekranı kapatır, uygulamadan çıkmaz
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc)
	await _frames(40)
	_expect(menu._lisanslar == null and current_scene == menu, "Escape Lisanslar'ı kapattı, menü duruyor")
	_expect(not root.get_node("SahneGecis").geri_yakalayici.is_valid(), "geri yakalayıcı boşaltıldı")

	# Yeniden açılır, geri düğmesi kapatır
	_touch(merkez, true)
	await _frames(190)
	_touch(merkez, false)
	await _frames(30)
	_expect(menu._lisanslar != null, "ikinci kez açıldı")
	if menu._lisanslar:
		_tap(menu._lisanslar._geri.get_global_rect().get_center())
		await _frames(40)
		_expect(menu._lisanslar == null, "geri düğmesi kapattı")

	# Kapandıktan sonra menü yine çalışır (ses düğmesi)
	var ses := root.get_node("SesYoneticisi")
	var mod: int = ses.mod
	_tap(menu._ses_dugmesi.get_global_rect().get_center())
	await _frames(10)
	_expect(ses.mod != mod, "kapandıktan sonra menü dokunma alıyor")
	ses.mod = mod
	ses._uygula()
	ses._kaydet()
	_bitir()


func _bitir() -> void:
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


func _butun_yazi(ekran: Control) -> String:
	var parcalar := PackedStringArray()
	for cocuk in ekran._icerik.get_children():
		if cocuk is Label:
			parcalar.append(cocuk.text)
	return "\n".join(parcalar)


func _touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	root.push_input(ev, true)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	_touch(pos, false)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(ad: String) -> void:
	if out == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(ad + ".png"))


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HATA: " + message)
