extends CanvasLayer
# Sahne geçişleri (autoload: SahneGecis).
# - Sahneler arasında yumuşak kararma/açılma
# - Ana menüye dönüş
# - Ekran yönü: her oyun dikey ya da yatay olabilir; geçişte ekran karartılınca döndürülür
# - Android geri tuşu ve bilgisayarda Escape: oyundayken ana menüye döner, ana menüdeyken uygulamadan çıkar
#
# Kullanım:
#   SahneGecis.sahne_degistir("res://oyunlar/hafiza/hafiza.tscn")
#   SahneGecis.ana_menuye_don()
#   SahneGecis.sahneyi_yeniden_baslat()
#
# Oyun yönünü bildirmek: oyunun ana sahnesinin kök düğüm script'ine şunu ekle
#   @export_enum("dikey", "yatay") var ekran_yonu: String = "yatay"
# Bu değişkeni olmayan sahneler dikey sayılır. Ana menü her zaman dikeydir.

const ANA_MENU := "res://ana_menu/ana_menu.tscn"
const DIKEY := "dikey"
const YATAY := "yatay"
const DIKEY_BOYUT := Vector2i(720, 1280)
const YATAY_BOYUT := Vector2i(1280, 720)
const KARARMA_SURESI := 0.28
const ACILMA_SURESI := 0.38
const PERDE_RENGI := Color("2d2447")

var gecis_suruyor: bool = true      # açılış perdesi kalkana kadar geri tuşu çalışmasın
var ekran_yonu: String = DIKEY      # şu an uygulanan yön (proje ayarları dikey başlar)
var _perde: ColorRect


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_perde = ColorRect.new()
	_perde.color = PERDE_RENGI
	_perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_perde)
	# Uygulama açılırken ilk sahne de yumuşakça belirsin
	_perde.modulate.a = 1.0
	_baslangic.call_deferred()


# İlk sahne (ana menü ya da F6 ile doğrudan açılan bir oyun) yatay ise perde kapalıyken
# ekranı döndürüp sahneyi yeni boyutla yeniden yükle
func _baslangic() -> void:
	var sahne := get_tree().current_scene
	if sahne and sahne_yonu(sahne) != ekran_yonu:
		var yeni := _yukle(sahne.scene_file_path)
		if yeni:
			await _yonu_uygula(sahne_yonu(yeni))
			get_tree().change_scene_to_node(yeni)
			await get_tree().process_frame
			await get_tree().process_frame
	_ac()


func _ac() -> void:
	var tween := create_tween()
	tween.tween_property(_perde, "modulate:a", 0.0, ACILMA_SURESI).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	gecis_suruyor = false


# Ekranı yumuşakça karartır; perde kapalıyken gerekirse ekranı döndürür, sahneyi değiştirir, sonra açar
func sahne_degistir(yol: String) -> void:
	if gecis_suruyor:
		return
	gecis_suruyor = true
	# Geçiş sırasında eski sahne dursun, dokunmalar ona gitmesin
	var mevcut := get_tree().current_scene
	if mevcut:
		mevcut.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(_perde, "modulate:a", 1.0, KARARMA_SURESI).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().paused = false
	var yeni := _yukle(yol)
	if yeni == null:
		if mevcut:
			mevcut.process_mode = Node.PROCESS_MODE_INHERIT
		_ac()
		return
	# Yeni sahne henüz ağaca girmedi (_ready çalışmadı); önce ekran yönü, sonra sahne
	await _yonu_uygula(sahne_yonu(yeni))
	get_tree().change_scene_to_node(yeni)
	# Yeni sahne karenin sonunda yerleşir; iki kare bekleyip perdeyi aç
	await get_tree().process_frame
	await get_tree().process_frame
	_ac()


func ana_menuye_don() -> void:
	sahne_degistir(ANA_MENU)


func sahneyi_yeniden_baslat() -> void:
	var sahne := get_tree().current_scene
	if sahne:
		sahne_degistir(sahne.scene_file_path)


func ana_menude_mi() -> bool:
	var sahne := get_tree().current_scene
	return sahne != null and sahne.scene_file_path == ANA_MENU


# Sahnenin istediği yön: kök düğümdeki ekran_yonu ("dikey"/"yatay"); yoksa dikey. Ana menü hep dikey.
func sahne_yonu(sahne: Node) -> String:
	if sahne.scene_file_path == ANA_MENU:
		return DIKEY
	return YATAY if sahne.get("ekran_yonu") == YATAY else DIKEY


func _yukle(yol: String) -> Node:
	var paket := load(yol) as PackedScene
	if paket == null:
		push_error("SahneGecis: sahne yüklenemedi: %s" % yol)
		return null
	return paket.instantiate()


# Ekran yönünü uygular: çizim boyutu (720x1280 / 1280x720), mobilde ekranı döndürür,
# bilgisayarda pencereyi çevirir. Ekran gerçekten dönene kadar (en fazla ~0.5 sn) bekler.
func _yonu_uygula(yon: String) -> void:
	if yon == ekran_yonu:
		return
	ekran_yonu = yon
	var yatay := yon == YATAY
	get_tree().root.content_scale_size = YATAY_BOYUT if yatay else DIKEY_BOYUT
	if DisplayServer.get_name() == "headless":
		return
	var pencere := get_window()
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(
			DisplayServer.SCREEN_SENSOR_LANDSCAPE if yatay else DisplayServer.SCREEN_PORTRAIT)
	elif pencere.mode == Window.MODE_WINDOWED:
		# Test penceresi: uzun ve kısa kenarı yer değiştir, ekranda ortala
		var uzun := maxi(pencere.size.x, pencere.size.y)
		var kisa := mini(pencere.size.x, pencere.size.y)
		pencere.size = Vector2i(uzun, kisa) if yatay else Vector2i(kisa, uzun)
		pencere.move_to_center()
	for i in 30:
		await get_tree().process_frame
		if (pencere.size.x > pencere.size.y) == yatay:
			break


func geri() -> void:
	if gecis_suruyor:
		return
	if ana_menude_mi():
		get_tree().quit()
	else:
		ana_menuye_don()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		geri()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		geri()
