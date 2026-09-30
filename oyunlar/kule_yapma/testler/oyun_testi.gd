extends SceneTree
# Kule Yapma oynanış testi (headless). Proje kökünden:
#   godot --headless --fixed-fps 60 --path . -s res://oyunlar/kule_yapma/testler/oyun_testi.gd
# Denetler: bölüm verisi (12 bölüm, 5 → 20 kat); oturma / mükemmel / ıska kararı; ıskada kule değişmez ve yeni kat
# gelir; mıknatısla oturan kat tam ortaya hizalanır; son kat çatı; duraklatma; 12 bölüm dokunarak bitirilir,
# apartmanlar ve ilerleme kaydedilir; sonsuz modda rekor; galeri ve apartman görünümü açılır.
# user://kule_yapma.cfg başta yedeklenir, sonda geri yazılır. Hata varsa çıkış kodu 1.

const Bolumler := preload("res://oyunlar/kule_yapma/bolumler.gd")
const Kayit := preload("res://oyunlar/kule_yapma/kayit.gd")

var failures := 0
var game: Node
var _yedek: PackedByteArray
var _yedek_var := false


func _initialize() -> void:
	root.content_scale_size = Vector2i(720, 1280)
	_yedek_var = FileAccess.file_exists(Kayit.PATH)
	if _yedek_var:
		_yedek = FileAccess.get_file_as_bytes(Kayit.PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	_veri_denetle()
	game = load("res://oyunlar/kule_yapma/kule_yapma.tscn").instantiate()
	root.add_child(game)
	await frames(30)
	_expect(game.durum == game.Durum.GIRIS, "giriş ekranıyla açılır")
	tap(game._oynat.get_global_rect().get_center())
	await frames(10)
	_expect(game.durum == game.Durum.OYUN, "oynat oyunu başlatır")
	await _iska_denetle()
	await _miknatis_denetle()
	await _duraklat_denetle()
	for i in Bolumler.LEVELS.size():
		if not await _bolum_oyna(i):
			break
	await _sonsuz_denetle()
	await _galeri_denetle()
	game.queue_free()
	await process_frame
	if _yedek_var:
		var f := FileAccess.open(Kayit.PATH, FileAccess.WRITE)
		f.store_buffer(_yedek)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Kayit.PATH))
	print("SONUÇ: ", "hepsi geçti" if failures == 0 else "%d hata" % failures)
	quit(1 if failures > 0 else 0)


func _veri_denetle() -> void:
	_expect(Bolumler.validate().is_empty(), "bölüm verisi geçerli: %s" % [Bolumler.validate()])
	_expect(Bolumler.LEVELS.size() >= 12, "en az 12 bölüm")
	_expect(int(Bolumler.LEVELS[0]["hedef"]) == 5 and int(Bolumler.LEVELS.back()["hedef"]) <= 20, "5 kattan başlar, en fazla 20")
	for i in range(1, Bolumler.LEVELS.size()):
		var a: Dictionary = Bolumler.LEVELS[i - 1]
		var b: Dictionary = Bolumler.LEVELS[i]
		_expect(b["hedef"] >= a["hedef"] and b["hiz"] >= a["hiz"] and b["tolerans"] <= a["tolerans"], "bölüm %d zorluğu yavaş artar" % (i + 1))
	_expect(Bolumler.sonsuz_mu(Bolumler.LEVELS.size()) and int(Bolumler.level(99)["hedef"]) == 0, "12'den sonra sonsuz mod")


# Katın tepeye göre kaymasını (kat genişliği cinsinden) bekleyip dokunur
func birak_kayma(oran_min: float, oran_max: float) -> void:
	await bekle(func() -> bool: return game.vinc.hazir, 400)
	await bekle(func() -> bool:
		if game.vinc.asili == null:
			return false
		var k: float = absf(game.vinc.asili.global_position.x - game.kule.tepe().x) / game.vinc.asili.genislik()
		return k >= oran_min and k <= oran_max, 900)
	tap(Vector2(360, 900))


func kat_bekle() -> void:
	await bekle(func() -> bool: return game.vinc.hazir or game.durum != game.Durum.OYUN, 600)


func _iska_denetle() -> void:
	var once: int = game.kule.sayi()
	var tepe: Vector2 = game.kule.tepe()
	# Bölüm 1'de tolerans çok geniş: en uca yakın bırakmak da oturmalı; ıska için hayali olarak kayıyı zorla
	await birak_kayma(0.0, 0.03)
	await kat_bekle()
	_expect(game.kule.sayi() == once + 1, "ortaya bırakılan kat oturdu")
	_expect(game._kombo >= 1, "tam orta mükemmel sayıldı")
	# Karar fonksiyonu: tolerans dışı ıska
	_expect(game.kule.karar(tepe.x + 240.0 * 0.95, 0.92, 240.0) == "iska", "tolerans dışı ıska")
	_expect(game.kule.karar(tepe.x + 240.0 * 0.5, 0.92, 240.0) == "oturur", "tolerans içi oturur")
	_expect(game.kule.karar(tepe.x + 5.0, 0.92, 240.0) == "mukemmel", "tam orta mükemmel")
	# Gerçek ıska: toleransı geçici daralt, uçta bırak
	var eski: float = game.level["tolerans"]
	game.level = game.level.duplicate()
	game.level["tolerans"] = 0.05
	var sayi: int = game.kule.sayi()
	await birak_kayma(0.25, 2.0)
	await kat_bekle()
	await frames(20)
	_expect(game.kule.sayi() == sayi, "ıskada kule değişmez")
	_expect(game.vinc.asili != null, "ıskadan sonra yeni kat gelir")
	game.level["tolerans"] = eski


func _miknatis_denetle() -> void:
	var sayi: int = game.kule.sayi()
	await birak_kayma(0.3, 0.5)
	await kat_bekle()
	_expect(game.kule.sayi() == sayi + 1, "kısmen denk gelen kat mıknatısla oturdu")
	var son: Node2D = game.kule.katlar.back()
	_expect(absf(son.position.x) < 0.5, "oturan kat tam ortaya hizalandı (%.1f)" % son.position.x)
	_expect(game._kombo == 0, "mükemmel olmayan oturma komboyu sıfırlar")


func _duraklat_denetle() -> void:
	tap(game._duraklat.get_global_rect().get_center())
	await frames(5)
	_expect(game.get_tree().paused and game._perde.visible, "duraklatma")
	var sayi: int = game.kule.sayi()
	tap(Vector2(360, 900))
	await frames(40)
	_expect(game.kule.sayi() == sayi, "duraklatılmışken kat bırakılmaz")
	tap(game._devam.get_global_rect().get_center())
	await frames(5)
	_expect(not game.get_tree().paused, "devam")


func _bolum_oyna(i: int) -> bool:
	var bas: int = game.kayit.bolum
	_expect(bas == i, "sıradaki bölüm %d (kayıttaki %d)" % [i + 1, bas])
	var hedef := int(Bolumler.level(i)["hedef"])
	var deneme := 0
	while game.durum == game.Durum.OYUN and deneme < 60:
		deneme += 1
		await birak_kayma(0.0, 0.2)
		await kat_bekle()
	_expect(game.kule.sayi() == hedef, "bölüm %d: %d kat (hedef %d)" % [i + 1, game.kule.sayi(), hedef])
	_expect(game.kule.cati_var(), "bölüm %d: son kat çatı" % (i + 1))
	await bekle(func() -> bool: return game.durum == game.Durum.SONU, 600)
	if game.durum != game.Durum.SONU:
		_expect(false, "bölüm %d sonu paneli açılmadı" % (i + 1))
		return false
	var ayar := ConfigFile.new()
	ayar.load(Kayit.PATH)
	_expect(int(ayar.get_value("ilerleme", "bolum", -1)) == i + 1, "bölüm %d sonrası kayıt" % (i + 1))
	_expect((ayar.get_value("apartmanlar", "liste", []) as Array).size() == i + 1, "bölüm %d apartmanı kaydedildi" % (i + 1))
	if i == 0:
		# Apartmanım: pencereye dokun, geri dön
		tap(game._sonu_apartman.get_global_rect().get_center())
		await frames(30)
		_expect(game._apartman.acik_mi(), "apartman görünümü açıldı")
		var blok: Node2D = game._apartman._bloklar[1]
		tap(blok.to_global(blok._pencereler[0]))
		await frames(5)
		_expect(blok._mesgul[0], "pencereye dokununca hayvan iş yapıyor")
		tap(game._apartman._kapat.get_global_rect().get_center())
		await frames(30)
		_expect(game.durum == game.Durum.SONU, "apartmandan bölüm sonuna dönüldü")
	tap(game._sonu_devam.get_global_rect().get_center())
	await bekle(func() -> bool: return game.durum == game.Durum.OYUN and game.vinc.hazir, 600)
	print("bölüm %d tamam" % (i + 1))
	return true


func _sonsuz_denetle() -> void:
	_expect(Bolumler.sonsuz_mu(game.kayit.bolum), "12 bölümden sonra sonsuz mod")
	_expect(int(game.level["hedef"]) == 0, "sonsuz modda hedef yok")
	for i in 6:
		await birak_kayma(0.0, 0.2)
		await kat_bekle()
	_expect(game.durum == game.Durum.OYUN, "sonsuz mod bitmez")
	_expect(game.kayit.rekor == game.kule.sayi() and game.kayit.rekor >= 6, "rekor kaydedildi (%d)" % game.kayit.rekor)
	var ayar := ConfigFile.new()
	ayar.load(Kayit.PATH)
	_expect(int(ayar.get_value("ilerleme", "rekor", 0)) == game.kayit.rekor, "rekor dosyada")


func _galeri_denetle() -> void:
	var sayi: int = game.kayit.apartmanlar.size()
	game._geri_basildi()
	await frames(20)
	_expect(game.durum == game.Durum.GIRIS, "geri giriş ekranına döner")
	_expect(game.kayit.apartmanlar.size() == sayi + 1, "sonsuz moddan çıkınca kule apartmanlara eklendi")
	tap(game._galeri_dugme.get_global_rect().get_center())
	await frames(20)
	_expect(game._galeri.acik_mi() and game._galeri._kartlar.size() == game.kayit.apartmanlar.size(), "galeri bütün apartmanları gösterir")
	tap(game._galeri._kartlar[0]["rect"].get_center() + Vector2(0, 150))
	await frames(30)
	_expect(game._apartman.acik_mi(), "galeriden apartman açıldı")
	tap(game._apartman._kapat.get_global_rect().get_center())
	await frames(30)
	_expect(game._galeri.acik_mi(), "apartmandan galeriye dönüldü")


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
