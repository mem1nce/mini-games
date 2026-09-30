extends Node
# Tek parmakla sürükle-bırak girdisi (DragInput). Oyun sahnesine düğüm olarak eklenir; dokunmaları
# kendisi (_input) okur ve sinyallerle bildirir:
#   - Aynı anda yalnızca bir parmak (active_touch) bir şey tutabilir; diğer parmaklar yok sayılır.
#   - Basılı tutunca çalışan geri düğmesi (ortak/basili_geri_dugmesi.gd) varsa önce ona bakılır.
#   - Sahne geçişi sürerken bütün dokunuşlar yok sayılır.
#   - Dokunma sistem tarafından iptal edilirse ya da uygulama arka plana giderse tutulan nesne
#     item_canceled ile bildirilir (oyun onu yerine gönderir).
# Nesneler ortak/suruklenebilir.gd'yi extends eder. Gölge Eşleştirme ve Hayvanları Besle kullanır.

const Draggable := preload("res://ortak/suruklenebilir.gd")
const HoldButton := preload("res://ortak/basili_geri_dugmesi.gd")

## Parmakla bir nesne tutuldu (nesne büyüyüp parmağın üstüne çıktı)
signal item_grabbed(item: Draggable)
## Tutulan nesne hareket etti; point nesnenin görünen hedef noktası (parmağın biraz üstü)
signal item_moved(item: Draggable, point: Vector2)
## Parmak kalktı; point bırakılan nokta. Nesnenin nereye gideceğine oyun karar verir.
signal item_dropped(item: Draggable, point: Vector2)
## Sürükleme iptal oldu (sistem iptali, uygulama arka planda, cancel()); oyun nesneyi geri göndermeli
signal item_canceled(item: Draggable)
## Hiçbir nesne tutulmadan yapılan dokunuş (ör. bir karaktere dokunma)
signal tapped(pos: Vector2)
## Her basış ve sürüklemede (ipucu sayacını sıfırlamak için)
signal touched

## Sürüklenebilir nesneler (oyun her bölümde günceller)
var items: Array = []
## false iken nesneler tutulamaz ve tapped gelmez (geri düğmesi yine çalışır)
var enabled: bool = true
var back_button: HoldButton = null
## Yakalama alanı, görselin bu kadar katı (1'den büyük: görselin biraz dışından da tutulabilir)
var grab_padding: float = 1.25
## Sürüklerken nesne parmağın bu kadar piksel üstünde durur
var lift: float = 70.0
## Sürüklerken nesnenin büyüme oranı
var drag_scale: float = 1.15
## Bırakma toleransı: hedef alanı her yönde (kısa kenarına göre) bu oranda büyütülür (drop_area()).
## Bırakma kararını oyun verir; bu değeri kullanan oyunlar ayarı buradan alır.
var drop_tolerance: float = 0.35

var active_touch: int = -1       # şu an bir şey tutan parmak (-1: yok)
var dragged: Draggable = null
var _holding_back: bool = false


func _input(event: InputEvent) -> void:
	if SahneGecis.gecis_suruyor:
		return
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed:
			_on_press(touch.index, touch.position)
		elif touch.index == active_touch:
			_on_release(touch.canceled)
		return
	var drag := event as InputEventScreenDrag
	if drag and drag.index == active_touch:
		touched.emit()
		if dragged:
			dragged.drag_to(drag.position)
			item_moved.emit(dragged, dragged.drop_point())


func _on_press(index: int, pos: Vector2) -> void:
	touched.emit()
	# Başka bir parmak zaten bir şey tutuyorsa bu dokunuş yok sayılır
	if active_touch != -1:
		return
	if back_button and back_button.contains(pos):
		active_touch = index
		_holding_back = true
		back_button.press()
		return
	if not enabled:
		return
	var item := item_at(pos)
	if item == null:
		tapped.emit(pos)
		return
	active_touch = index
	dragged = item
	item.grab(pos, lift, drag_scale)
	item_grabbed.emit(item)


func _on_release(canceled: bool) -> void:
	active_touch = -1
	touched.emit()
	if _holding_back:
		_holding_back = false
		back_button.release()
		return
	if dragged == null:
		return
	var item := dragged
	dragged = null
	item.dragging = false
	if canceled or not is_instance_valid(item):
		if is_instance_valid(item):
			item_canceled.emit(item)
		return
	item_dropped.emit(item, item.drop_point())


# Tutulan nesneyi bırakır (ör. bölüm biterken); oyun item_canceled ile onu geri gönderir
func cancel() -> void:
	if dragged:
		_on_release(true)


# Uygulama arka plana giderse tutulan nesne yerine döner
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active_touch != -1:
		_on_release(true)


# Hedef alanının bırakma toleransıyla büyütülmüş hali (cömert bırakma)
func drop_area(target: Rect2) -> Rect2:
	return target.grow(minf(target.size.x, target.size.y) * drop_tolerance)


# Parmağa en yakın, tutulabilir nesne (yakalama alanı görselden biraz büyük)
func item_at(pos: Vector2) -> Draggable:
	var best: Draggable = null
	var best_distance := INF
	for entry in items:
		if not is_instance_valid(entry):
			continue
		var item: Draggable = entry
		if not item.can_grab():
			continue
		var distance: float = item.grab_distance(pos, grab_padding)
		if distance < best_distance:
			best_distance = distance
			best = item
	return best
