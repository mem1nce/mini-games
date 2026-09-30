class_name ColoringTool
extends RefCounted
# Boyama araçlarının ortak arayüzü. Tuval, aracın parmağını izler ve dokunmayı sayfa pikseline çevirip verir:
#   begin(pos)  parmak değdi          move(pos)  parmak kaydı
#   end()       parmak kalktı: yapılan iş tek bir kayıt olarak geri alma yığınına girer (canvas.commit)
#   cancel()    iptal: ikinci parmak hemen gelince (avuç içi koruması) yapılanı iz bırakmadan geri al
# Yeni araç: bu script'i extends eden bir script yaz, arac_cubugu.gd'ye düğmesini ekle.

var canvas: ColoringCanvas
var color: Color = Color.WHITE


func begin(_pos: Vector2) -> void:
	pass


func move(_pos: Vector2) -> void:
	pass


func end() -> void:
	pass


func cancel() -> void:
	pass


## Şu anki iş, ikinci parmak gelince iptal edilecek kadar küçük mü (kısa bir çizgi, yeni bir dokunuş)?
func is_small() -> bool:
	return true


## Fırça sesi gibi sürekli ses: "" (yok), "firca" ya da "silgi"
func loop_sound() -> String:
	return ""
