extends Camera2D
# Kulenin tepesini yumuşakça izleyen kamera: tepe ekranın alt yarısında (TEPE_EKRAN_Y) kalacak şekilde yukarı kayar,
# hiç aşağı inmez (bölüm başında sıfırlanır). Yatayda sabit.

const TEPE_EKRAN_Y := 820.0

var ekran := Vector2(720, 1280)
var hedef_y := 640.0
var baslangic_y := 640.0


func kur(p_ekran: Vector2) -> void:
	ekran = p_ekran
	baslangic_y = ekran.y * 0.5
	sifirla()


func sifirla() -> void:
	hedef_y = baslangic_y
	position = Vector2(ekran.x * 0.5, baslangic_y)


# Tepenin dünyadaki y'si: tepe ekranda TEPE_EKRAN_Y'nin üstüne çıktıysa kamera yükselir
func tepeyi_izle(tepe_y: float) -> void:
	var gereken := tepe_y - TEPE_EKRAN_Y + ekran.y * 0.5
	hedef_y = minf(hedef_y, minf(baslangic_y, gereken))


func sol_ust() -> Vector2:
	return position - ekran * 0.5


func _process(delta: float) -> void:
	position.y = lerpf(position.y, hedef_y, 1.0 - exp(-delta * 2.6))
