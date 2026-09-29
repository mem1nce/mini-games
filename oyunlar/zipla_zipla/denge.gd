class_name JumpBalance
extends Resource
# Zıpla Zıpla'nın bütün denge ayarları (tek yer: denge.tres).
# Zorluk, tırmanılan basamak sayısına göre artar: ilk `easy_steps` basamak başlangıç değerlerinde kalır,
# sonra `ramp_steps` basamak boyunca başlangıç değerinden sınır değerine geçilir (`ramp_curve` boşsa
# doğrusal). Basamak 0 başlangıç basamağıdır (hareket etmez, kaybolmaz).

@export_group("Zorluk eğrisi")
## Bu basamağa kadar oyun en kolay hâlinde kalır (çocuk oyunu öğrensin).
@export_range(0, 50) var easy_steps: int = 5
## Kolay basamaklardan sonra en zor hâle kaç basamakta varılır.
@export_range(1, 500) var ramp_steps: int = 60
## Zorluğun artış şekli (x: 0..1 ilerleme, y: 0..1 zorluk). Boşsa doğrusal.
@export var ramp_curve: Curve

@export_group("Basamak hızı")
## İlk basamakların yatay hızı (px/sn).
@export var speed_start: float = 100.0
## En zor hâldeki yatay hız (px/sn).
@export var speed_max: float = 290.0
## Her basamağın hızı bu oranda rastgele farklı olur (0.2 = ±%20).
@export_range(0.0, 0.5, 0.01) var speed_variation: float = 0.2
## Basamağın ekran ortasından en fazla kayabileceği mesafe (px); ekran kenarı da sınırdır.
@export var travel_half: float = 380.0
## Adil oyun payı (sn): basamağın gidip gelme mesafesi, üstteki basamak kurbağanın durduğu basamak
## kaybolmadan en az bu kadar önce uygun yere gelecek şekilde kısaltılır (travel_for).
@export_range(0.3, 3.0, 0.05) var reaction_time: float = 1.0

@export_group("Basamak genişliği")
## İlk basamakların genişliği (px). Görsel döşeme yüzünden 160 + 60k'ya yuvarlanır (160, 220, 280, 340...).
@export var width_start: float = 340.0
## En dar basamak (px, alt sınır).
@export var width_min: float = 160.0

@export_group("Kaybolma")
## Üzerinde durulan basamağın ilk başlardaki kaybolma süresi (sn).
@export var vanish_start: float = 5.0
## Kaybolma süresinin alt sınırı (sn).
@export var vanish_min: float = 2.0
## Kaybolmadan önce titreyip solma süresi (sn); kaybolma süresinin yarısını geçmez.
@export var warn_time: float = 1.2

@export_group("Ödüller")
## İlk basamaklarda bir basamağın ödüllü olma olasılığı.
@export_range(0.0, 1.0, 0.01) var reward_chance_start: float = 0.5
## En zor hâlde ödül olasılığı.
@export_range(0.0, 1.0, 0.01) var reward_chance_end: float = 0.4
## Ödül türleri (ağırlıklarına göre seçilir).
@export var rewards: Array[JumpRewardType] = []

@export_group("Konma")
## Kurbağa genişliğinin en az bu kadarı basamakla çakışıyorsa konar (0.3 = %30).
@export_range(0.05, 1.0, 0.01) var land_overlap_ratio: float = 0.3
## Konma hesabında kurbağanın genişliği (px).
@export var player_width: float = 110.0
## Kenara konunca basamağın içine doğru kayma oranı (0: kaymaz, 1: tamamen basamağın üstüne).
@export_range(0.0, 1.0, 0.05) var edge_slide: float = 0.8
## Kenardan içeri kayma süresi (sn).
@export var slide_time: float = 0.2

@export_group("Zıplama")
## Zıplamada tepe noktasına çıkış süresi (sn); kısa = hızlı, net zıplama.
@export_range(0.1, 0.8, 0.01) var jump_rise_time: float = 0.26
## Tepe noktasının üstteki basamağın ne kadar üstünde olduğu (px).
@export var jump_clearance: float = 60.0

@export_group("Düzen")
## İki basamak arasındaki dikey mesafe (px).
@export var step_gap: float = 210.0
## Kurbağanın durduğu basamak ekran yüksekliğinin bu oranında durur (0 üst, 1 alt).
@export_range(0.5, 0.9, 0.01) var player_screen_ratio: float = 0.78


# 0 (kolay) .. 1 (en zor)
func difficulty(step: int) -> float:
	if step <= easy_steps:
		return 0.0
	var t := clampf(float(step - easy_steps) / float(ramp_steps), 0.0, 1.0)
	if ramp_curve:
		t = clampf(ramp_curve.sample_baked(t), 0.0, 1.0)
	return t


func speed_for(step: int) -> float:
	return lerpf(speed_start, speed_max, difficulty(step))


func width_for(step: int) -> float:
	return maxf(width_min, lerpf(width_start, width_min, difficulty(step)))


func vanish_for(step: int) -> float:
	return maxf(vanish_min, lerpf(vanish_start, vanish_min, difficulty(step)))


# Gidip gelme mesafesi (merkezden). Kısa tutulur ki en yavaş basamak bile yarım turunu
# (kaybolma - reaction_time) içinde bitirsin: böylece uygun an hep kaybolmadan önce gelir.
func travel_for(step: int, screen_limit: float) -> float:
	var slowest := speed_for(step) * (1.0 - speed_variation)
	var fair := slowest * maxf(0.1, vanish_for(step) - reaction_time) / 2.0
	return maxf(0.0, minf(minf(travel_half, screen_limit), fair))


func warn_for(step: int) -> float:
	return minf(warn_time, vanish_for(step) * 0.5)


func reward_chance_for(step: int) -> float:
	return lerpf(reward_chance_start, reward_chance_end, difficulty(step))


# Ağırlıklara göre bir ödül türü seçer (hiç tür yoksa null)
func pick_reward(rng: RandomNumberGenerator) -> JumpRewardType:
	var total := 0.0
	for reward in rewards:
		total += reward.weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for reward in rewards:
		roll -= reward.weight
		if roll < 0.0:
			return reward
	return rewards[-1]


# Değerleri denetler; sorunları döndürür (boşsa her şey yolunda)
func problems() -> PackedStringArray:
	var result := PackedStringArray()
	if speed_start > speed_max:
		result.append("speed_start, speed_max'tan büyük")
	if width_min > width_start:
		result.append("width_min, width_start'tan büyük")
	if width_min < 160.0:
		result.append("width_min en az 160 olmalı (basamak görselinin en küçük hâli)")
	if vanish_min > vanish_start:
		result.append("vanish_min, vanish_start'tan büyük")
	if vanish_min <= reaction_time + 0.3:
		result.append("vanish_min, reaction_time'dan en az 0.3 sn uzun olmalı")
	if rewards.is_empty():
		result.append("hiç ödül türü yok")
	for i in rewards.size():
		if rewards[i] == null or rewards[i].texture == null:
			result.append("%d. ödül türü eksik" % (i + 1))
	if jump_clearance < 0.0:
		result.append("jump_clearance eksi olamaz")
	return result
