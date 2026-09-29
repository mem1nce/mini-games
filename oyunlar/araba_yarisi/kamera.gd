extends Camera2D
# Kamera: çocuğun arabasını yumuşakça takip eder. Araba ekranın solunda üçte bir civarında durur,
# hız arttıkça kamera biraz daha ileri bakar. Rampadan zıplarken hafifçe uzaklaşır; havadayken
# yolla araba arasına bakar ki hem araba hem iniş yeri görünsün.

const CAR_X := 0.3              # arabanın ekrandaki yatay yeri (oran)
const CAR_Y := 0.68             # yolun (temas noktasının) ekrandaki dikey yeri (oran)
const LOOK_AHEAD := [30.0, 170.0]
const AIR_ZOOM := 0.86
const FOLLOW_X := 7.0
const FOLLOW_Y := 3.2

var _ahead := 30.0


# Kamerayı anında yerine koyar (yarış başında)
func snap_to(car: Node2D) -> void:
	zoom = Vector2.ONE
	_ahead = LOOK_AHEAD[0]
	position = _goal(car, car.position.y)
	reset_smoothing()


func follow(car: Node2D, ground_y: float, delta: float) -> void:
	var airborne: bool = car.airborne
	var ratio: float = car.speed_ratio()
	_ahead = lerpf(_ahead, lerpf(LOOK_AHEAD[0], LOOK_AHEAD[1], clampf(ratio, 0.0, 1.0)), 1.0 - exp(-1.5 * delta))
	var target_zoom := AIR_ZOOM if airborne else 1.0
	zoom = Vector2.ONE * lerpf(zoom.x, target_zoom, 1.0 - exp(-(1.6 if airborne else 1.2) * delta))
	# Havadayken yere ve arabaya ortak bakar
	var focus_y := lerpf(ground_y, car.position.y, 0.45) if airborne else car.position.y
	var goal := _goal(car, focus_y)
	position.x = lerpf(position.x, goal.x, 1.0 - exp(-FOLLOW_X * delta))
	position.y = lerpf(position.y, goal.y, 1.0 - exp(-FOLLOW_Y * delta))


func _goal(car: Node2D, focus_y: float) -> Vector2:
	var view := get_viewport_rect().size / zoom
	return Vector2(car.position.x + view.x * (0.5 - CAR_X) + _ahead, focus_y - view.y * (CAR_Y - 0.5))
