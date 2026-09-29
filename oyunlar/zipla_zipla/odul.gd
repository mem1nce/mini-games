extends Node2D
# Collectible: basamağın üstündeki ödül (lolipop, kurabiye...). Her basamağın kendi ödül yuvası vardır;
# basamak havuzdan yeniden kurulunca ödül de yeniden kurulur ya da gizlenir. Hafifçe süzülerek durur.
# Sayaca uçuşu arayüz yapar (arayuz.gd fly_reward).

const SIZE := 72.0          # ekrandaki boyu (px)
const HOVER := 58.0         # basamak yüzeyinin ne kadar üstünde durur
const BOB := 7.0            # süzülme genliği

var type: JumpRewardType = null
var _sprite: Sprite2D
var _time := 0.0


func _init() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	position = Vector2(0, -HOVER)
	hide()


func setup(reward: JumpRewardType) -> void:
	type = reward
	visible = reward != null
	if reward:
		_sprite.texture = reward.texture
		_sprite.scale = Vector2.ONE * SIZE / reward.texture.get_width()
		_time = randf() * TAU


func has_reward() -> bool:
	return type != null and visible


# Toplanır: görünmez olur ve türünü döndürür (arayüz kopyasını sayaca uçurur)
func collect() -> JumpRewardType:
	var reward := type
	type = null
	hide()
	return reward


func sprite_global_position() -> Vector2:
	return _sprite.get_global_transform_with_canvas().origin


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_sprite.position.y = sin(_time * 2.6) * BOB
	_sprite.rotation = sin(_time * 1.7) * 0.08
