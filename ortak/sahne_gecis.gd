extends CanvasLayer
# Sahne geçişleri (autoload: SahneGecis).
# - Sahneler arasında yumuşak kararma/açılma
# - Ana menüye dönüş
# - Android geri tuşu ve bilgisayarda Escape: oyundayken ana menüye döner, ana menüdeyken uygulamadan çıkar
#
# Kullanım:
#   SahneGecis.sahne_degistir("res://oyunlar/hafiza/hafiza.tscn")
#   SahneGecis.ana_menuye_don()
#   SahneGecis.sahneyi_yeniden_baslat()

const ANA_MENU := "res://ana_menu/ana_menu.tscn"
const KARARMA_SURESI := 0.28
const ACILMA_SURESI := 0.38
const PERDE_RENGI := Color("2d2447")

var gecis_suruyor: bool = false
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
	_ac.call_deferred()


func _ac() -> void:
	var tween := create_tween()
	tween.tween_property(_perde, "modulate:a", 0.0, ACILMA_SURESI).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	gecis_suruyor = false


# Ekranı yumuşakça karartır, sahneyi değiştirir, sonra yeniden açar
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
	get_tree().change_scene_to_file(yol)
	# Yeni sahne karenin sonunda yüklenir; bir kare bekleyip perdeyi aç
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


# Android geri tuşu / Escape
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
