extends SceneTree
# Tren Rayı ses testi (headless). Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://oyunlar/tren_rayi/testler/ses_testi.gd
# Denetler: giriş ekranında trene dokununca düdük; kalkışta düdük; tren hareket ederken "çuf çuf" döngüsü çalar
# ve perdesi trenin hızıyla artıp azalır (yavaşken pes, hızlıyken tiz); tren durunca döngü susar ve fren sesi
# çalar; istasyona varışta fren ve düdük; ekrandan çıkınca döngü çalmaz.
# user://tren_rayi.cfg başta yedeklenir, sonda geri yazılır. Hata varsa çıkış kodu 1.

const Baglanti := preload("res://oyunlar/tren_rayi/baglanti.gd")
const Yonetici := preload("res://oyunlar/tren_rayi/bolum_yoneticisi.gd")
const CUF := "tren_cufcuf"

var failures := 0
var game: Node
var ses: Node
var istenen: Array[String] = []
var _yedek: PackedByteArray
var _yedek_var := false


func _initialize() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	ses = root.get_node("SesYoneticisi")
	ses.ses_istendi.connect(func(ad: String) -> void: istenen.append(ad))
	_yedek_var = FileAccess.file_exists(Yonetici.PATH)
	if _yedek_var:
		_yedek = FileAccess.get_file_as_bytes(Yonetici.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Yonetici.PATH))
	game = load("res://oyunlar/tren_rayi/tren_rayi.tscn").instantiate()
	root.add_child(game)
	await frames(60)

	# Giriş ekranı: trene dokununca düdük, "çuf çuf" yok
	_expect(not _dongu_caliyor(), "giriş ekranında çuf çuf çalmıyor")
	tap(game._giris.tren.loko_konumu())
	await frames(5)
	_expect(istenen.count("tren_duduk") == 1, "giriş ekranında trene dokununca düdük (%s)" % [istenen])
	tap(game._giris._oynat.position)
	await frames(40)

	# Eksik yol: kalkışta düdük, giderken çuf çuf, durunca fren, dönerken yine çuf çuf, sonunda sessiz
	istenen.clear()
	tap(game._hareket.get_global_rect().get_center())
	await frames(3)
	_expect(istenen.has("tren_duduk"), "kalkışta düdük")
	var olcum := await _yolculugu_izle(func() -> bool: return game.durum == game.Durum.OYUN, 1500)
	_expect(olcum["hareketli_kare"] > 10 and olcum["sessiz_hareket"] <= 4, "hareket ederken çuf çuf çaldı (%s)" % olcum)
	_expect(olcum["duruk_calan"] <= 20, "tren dururken çuf çuf sustu (%s)" % olcum)
	_expect(istenen.count("tren_fren") == 1, "eksik yolda durunca fren sesi (%d)" % istenen.count("tren_fren"))
	await frames(30)
	_expect(not _dongu_caliyor(), "yolculuk bitince çuf çuf çalmıyor")

	# Tam yol: perde hızla artıp azalır, duraklarda ve istasyonda fren, istasyonda düdük
	await coz()
	var yolcu: int = game.izgara.yolcular.size()
	istenen.clear()
	tap(game._hareket.get_global_rect().get_center())
	olcum = await _yolculugu_izle(func() -> bool: return game.durum == game.Durum.KUTLAMA, 3000)
	print("tam yolculuk: ", olcum)
	_expect(game.durum == game.Durum.KUTLAMA, "tren istasyona vardı")
	_expect(olcum["en_pes"] < 0.85 and olcum["en_tiz"] > 1.15, "perde hızla değişti: %.2f - %.2f" % [olcum["en_pes"], olcum["en_tiz"]])
	_expect(olcum["uyum"] > 0.9, "perde trenin hızını izliyor (ilişki %.2f)" % olcum["uyum"])
	_expect(olcum["en_sesli"] <= game.CUF_DB_HIZLI + 0.01 and olcum["en_sesli"] > game.CUF_DB_YAVAS, "seviye sınırlar içinde (%.1f dB)" % olcum["en_sesli"])
	_expect(istenen.count("tren_duduk") == 2, "kalkışta ve varışta düdük (%d)" % istenen.count("tren_duduk"))
	_expect(istenen.count("tren_fren") == yolcu + 1, "her durakta ve istasyonda fren (%d, %d yolcu)" % [istenen.count("tren_fren"), yolcu])
	await frames(30)
	_expect(not _dongu_caliyor(), "istasyonda çuf çuf çalmıyor")
	for eski in ["cuf", "duduk", "hareket", "fren"]:
		_expect(not game._sesler.streams.has(eski), "eski '%s' sesi oyunda yok" % eski)

	# Yeni bölümde yola çıkıp yolculuk sürerken oyundan çıkınca döngü susar
	await bekle(func() -> bool: return game.durum == game.Durum.OYUN, 1200)
	await frames(30)
	await coz()
	tap(game._hareket.get_global_rect().get_center())
	await bekle(_dongu_caliyor, 120)
	await frames(10)
	_expect(_dongu_caliyor(), "yeni yolculukta çuf çuf çalıyor")
	game.queue_free()
	await frames(30)
	_expect(not _dongu_caliyor(), "oyundan çıkınca çuf çuf susar")

	if _yedek_var:
		var f := FileAccess.open(Yonetici.PATH, FileAccess.WRITE)
		f.store_buffer(_yedek)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Yonetici.PATH))
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


# Koşul sağlanana kadar her kare trenin hızını ve döngünün durumunu ölçer
func _yolculugu_izle(bitti: Callable, en_fazla: int) -> Dictionary:
	var sonuc := {"hareketli_kare": 0, "sessiz_hareket": 0, "duruk_calan": 0, "en_pes": 9.0, "en_tiz": 0.0,
		"en_sesli": -80.0, "uyum": 0.0}
	var hizlar: Array[float] = []
	var perdeler: Array[float] = []
	var onceki: float = game.tren.mesafe
	var tam_hiz: float = game.tren_hizi * game.izgara.hucre
	for i in en_fazla:
		await process_frame
		if bitti.call():
			break
		if not is_instance_valid(game.tren):
			continue
		var hiz: float = absf(game.tren.mesafe - onceki) * 60.0 / tam_hiz
		onceki = game.tren.mesafe
		var p: AudioStreamPlayer = ses._donguler.get(CUF)
		var caliyor: bool = p != null and p.playing and p.volume_db > -30.0
		if hiz > 0.15:
			sonuc["hareketli_kare"] += 1
			if not caliyor:
				sonuc["sessiz_hareket"] += 1
			else:
				hizlar.append(hiz)
				perdeler.append(p.pitch_scale)
				sonuc["en_pes"] = minf(sonuc["en_pes"], p.pitch_scale)
				sonuc["en_tiz"] = maxf(sonuc["en_tiz"], p.pitch_scale)
				sonuc["en_sesli"] = maxf(sonuc["en_sesli"], p.volume_db)
		elif hiz == 0.0 and caliyor:
			sonuc["duruk_calan"] += 1
	sonuc["uyum"] = _iliski(hizlar, perdeler)
	return sonuc


# İki dizinin doğrusal ilişkisi (Pearson): 1'e yakınsa perde hızla birlikte artıp azalıyor
func _iliski(a: Array[float], b: Array[float]) -> float:
	if a.size() < 3:
		return 0.0
	var oa := 0.0
	var ob := 0.0
	for i in a.size():
		oa += a[i]
		ob += b[i]
	oa /= a.size()
	ob /= b.size()
	var ab := 0.0
	var aa := 0.0
	var bb := 0.0
	for i in a.size():
		ab += (a[i] - oa) * (b[i] - ob)
		aa += (a[i] - oa) ** 2
		bb += (b[i] - ob) ** 2
	return ab / sqrt(maxf(aa * bb, 1e-9))


func _dongu_caliyor() -> bool:
	var p: AudioStreamPlayer = ses._donguler.get(CUF)
	return p != null and p.playing


# Parçalara dokunarak çözüm yönüne çevirir
func coz() -> void:
	var izgara: Node2D = game.izgara
	for h in izgara.parcalar:
		var parca: Node2D = izgara.parcalar[h]
		if parca.sabit or not izgara.bolum["cozum"].has(h):
			continue
		var hedef := Baglanti.acikliklar(izgara.bolum["cozum"][h]["tip"], izgara.bolum["cozum"][h]["yon"])
		for k in 4:
			if Baglanti.acikliklar(parca.tip, parca.yon) == hedef:
				break
			tap(izgara.merkez(h))
			await frames(2)


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


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HATA: " + message)
