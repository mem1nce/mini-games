extends SceneTree
# Zıpla Zıpla mantık testi (headless). Proje kökünden:
#   godot --headless --path . -s res://oyunlar/zipla_zipla/testler/mantik_testi.gd
# Denetler: denge.tres sorunsuz; konma toleransı sınırları; kenar kayması; zorluk eğrisi tekdüze ve
# sınırlarda; genişliklerin görsele uygun yuvarlanması; havuzun 300 basamak sonra da aynı boyda kalması.

const Platform := preload("res://oyunlar/zipla_zipla/basamak.gd")
const Spawner := preload("res://oyunlar/zipla_zipla/basamak_uretici.gd")

var _fails := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fails += 1
		printerr("HATA: " + message)


func _initialize() -> void:
	var balance: JumpBalance = load("res://oyunlar/zipla_zipla/denge.tres")
	_check(balance.problems().is_empty(), "denge.tres sorunlu: %s" % [balance.problems()])

	# Konma toleransı: 110 px kurbağa, %30 -> en az 33 px çakışma
	var platform: Node2D = Platform.new()
	root.add_child(platform)
	platform.setup(3, "kek", 220.0, 0.0, 640.0, 0.0, 640.0, false)
	var pw := 110.0
	var edge: float = platform.right()     # basamağın sağ kenarı
	_check(platform.can_land(edge + pw / 2.0 - 33.0, pw, 0.3), "%30 çakışmada konmalı")
	_check(not platform.can_land(edge + pw / 2.0 - 31.9, pw, 0.3), "%29 çakışmada konmamalı")
	_check(platform.can_land(640.0, pw, 0.3), "tam ortada konmalı")
	_check(not platform.can_land(edge + pw, pw, 0.3), "tamamen dışarıda konmamalı")
	_check(is_equal_approx(platform.overlap(640.0, pw), pw), "ortada çakışma kurbağa genişliği olmalı")
	# Kenar kayması: basamağın içindeyse değişmez, kenardan taşıyorsa içeri kayar
	var limit: float = platform.width / 2.0 - pw / 2.0
	_check(is_equal_approx(platform.settle_offset(10.0, pw, 0.8), 10.0), "içerideki ofset değişmemeli")
	var slid: float = platform.settle_offset(limit + 50.0, pw, 0.8)
	_check(slid < limit + 50.0 and slid >= limit, "kenardaki ofset içeri kaymalı (%f)" % slid)
	_check(is_equal_approx(platform.settle_offset(-(limit + 50.0), pw, 1.0), -limit), "tam kayma sınırda durmalı")
	# Ufalanan basamağa konulamaz
	platform.crumble()
	_check(not platform.can_land(640.0, pw, 0.3), "ufalanmış basamağa konmamalı")

	# Genişlik yuvarlama: 160 + 60k
	for w in [100.0, 160.0, 185.0, 200.0, 245.0, 340.0]:
		var snapped: float = Platform.snap_width(w)
		_check(snapped >= 160.0 and is_equal_approx(fmod(snapped - 160.0, 60.0), 0.0), "yuvarlama hatalı: %f -> %f" % [w, snapped])

	# Zorluk eğrisi: kolay basamaklar sabit, sonra tekdüze, sınırlarda
	for s in balance.easy_steps + 1:
		_check(is_equal_approx(balance.speed_for(s), balance.speed_start), "kolay basamakta hız sabit olmalı")
	var last_speed := 0.0
	var last_width := INF
	var last_vanish := INF
	for s in 400:
		var speed := balance.speed_for(s)
		var width := balance.width_for(s)
		var vanish := balance.vanish_for(s)
		_check(speed >= last_speed - 0.001 and width <= last_width + 0.001 and vanish <= last_vanish + 0.001, "eğri tekdüze değil (%d)" % s)
		_check(speed <= balance.speed_max + 0.001 and width >= balance.width_min - 0.001 and vanish >= balance.vanish_min - 0.001, "sınır aşıldı (%d)" % s)
		_check(balance.warn_for(s) <= vanish * 0.5 + 0.001, "uyarı süresi kaybolma süresinin yarısını geçmemeli")
		last_speed = speed
		last_width = width
		last_vanish = vanish

	# Havuz: 300 basamak tırmanınca da düğüm sayısı sabit, basamaklar doğru yerde
	var layer := Node2D.new()
	root.add_child(layer)
	var spawner: Node = Spawner.new()
	root.add_child(spawner)
	spawner.balance = balance
	spawner.layer = layer
	spawner.set_seed(1)
	spawner.build()
	spawner.reset(640.0, 1280.0)
	_check(spawner.platform(0).fixed, "başlangıç basamağı sabit olmalı")
	var reward_count := 0
	for s in range(1, 301):
		spawner.advance(s)
		var p: Node2D = spawner.platform(s)
		var above: Node2D = spawner.platform(s + 1)
		_check(p != null and above != null, "basamak eksik (%d)" % s)
		if p:
			_check(is_equal_approx(p.position.y, -s * balance.step_gap), "basamak yeri yanlış (%d)" % s)
			_check(p.left() >= 0.0 and p.right() <= 1280.0, "basamak ekrandan taşıyor (%d)" % s)
			if p.reward.has_reward():
				reward_count += 1
	_check(layer.get_child_count() == Spawner.POOL_SIZE, "havuz büyüdü: %d" % layer.get_child_count())
	_check(spawner.active_count() <= Spawner.POOL_SIZE, "aktif basamak sayısı havuzdan büyük")
	_check(reward_count > 60 and reward_count < 240, "ödül oranı beklenmedik: %d/300" % reward_count)

	if _fails == 0:
		print("mantik_testi: TAMAM")
	else:
		printerr("mantik_testi: %d hata" % _fails)
	quit(1 if _fails > 0 else 0)
