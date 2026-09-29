extends RefCounted
# Rakip yapay zekası (rubber band): yarış hep yakın geçsin, gaza basan çocuk çoğu zaman kazansın.
# Her rakip çocuğa göre bir "hedef mesafe" izler. Bu mesafe yavaşça dalgalanır: rakip bazen öne geçer,
# bazen geride kalır. Rakip hızını çocuğun hızına göre ayarlayarak o mesafeye yaklaşır:
# - Çocuk yavaşlarsa ya da durursa rakipler de yavaşlar (ama durmaz); çocuk öndeyse rakipler hızlanır.
# - Pistin son bölümünde hedef mesafe "biraz geride" olur ve rakip hızı sınırlanır: gaza basan çocuk kazanır.
#   Ama rakip orada çok da yavaşlamaz: hiç gaza basmayan çocuğu geçip önce bitirebilir.

const Araba := preload("res://oyunlar/araba_yarisi/araba.gd")

const GAP_CENTER := -220.0      # ortalama hedef: çocuğun biraz arkası (px; + önde)
const GAP_SWING := 340.0        # dalgalanma: öne geçip geride kalma
const SKILL_GAP := 1500.0       # hızlı rakip hedefini biraz daha öne koyar
const FOLLOW := 1.1             # mesafe farkını kapatma hızı (1/sn)
const MIN_FACTOR := 0.3         # çocuk dursa da rakip bu hızla ilerler
const MAX_FACTOR := 1.12
const FINAL_PART := 0.85        # pistin bu oranından sonra...
const FINAL_GAP := -420.0       # ...rakip çocuğun bu kadar arkasını hedefler
const FINAL_CAP := 0.95         # ...ve en hızlının en fazla bu kadarıyla gider
const FINAL_FLOOR := 0.55       # ...ama en az bu kadarıyla

var skill: float                # taban hız (en hızlının oranı, ~0.83-0.9)
var period: float
var phase: float


func _init(p_skill: float, p_phase: float, p_period: float = 30.0) -> void:
	skill = p_skill
	phase = p_phase
	period = p_period


# Rakibin hedef hızı (px/sn)
func target_speed(rival_s: float, player_s: float, player_speed: float, progress: float, time: float, player_finished: bool) -> float:
	if player_finished:
		return skill * Araba.MAX_SPEED
	var desired := GAP_CENTER + (skill - 0.85) * SKILL_GAP + sin(time * TAU / period + phase) * GAP_SWING
	var final := smoothstep(FINAL_PART, FINAL_PART + 0.05, progress)
	desired = lerpf(desired, FINAL_GAP, final)
	var gap := rival_s - player_s
	var speed := player_speed + (desired - gap) * FOLLOW
	var cap := lerpf(MAX_FACTOR, FINAL_CAP, final)
	var floor_factor := lerpf(MIN_FACTOR, FINAL_FLOOR, final)
	return clampf(speed, floor_factor * Araba.MAX_SPEED, cap * Araba.MAX_SPEED)
