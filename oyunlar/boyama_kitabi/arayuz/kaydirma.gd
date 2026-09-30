class_name ColoringScroller
extends RefCounted
# Dikey kaydırma (galeri, sayfa ızgarası, dar ekranda palet): parmak THRESHOLD pikselden fazla kayarsa
# dokunma kaydırmaya döner; bırakınca biraz daha kayar ve yavaşlar, uçlarda durur.

const THRESHOLD := 14.0

var offset: float = 0.0
var max_offset: float = 0.0
var scrolling: bool = false
var _start := Vector2.ZERO
var _start_offset: float = 0.0
var _velocity: float = 0.0
var _last_y: float = 0.0
var _last_time: int = 0


func press(pos: Vector2) -> void:
	_start = pos
	_start_offset = offset
	_velocity = 0.0
	_last_y = pos.y
	_last_time = Time.get_ticks_msec()
	scrolling = false


## Sürükleme; dokunma kaydırmaya döndüyse true
func drag(pos: Vector2) -> bool:
	if not scrolling and absf(pos.y - _start.y) > THRESHOLD and max_offset > 0.0:
		scrolling = true
		_start = pos
		_start_offset = offset
	if scrolling:
		offset = clampf(_start_offset - (pos.y - _start.y), 0.0, max_offset)
		var now := Time.get_ticks_msec()
		var dt := maxf(0.001, (now - _last_time) / 1000.0)
		_velocity = lerpf(_velocity, -(pos.y - _last_y) / dt, 0.5)
		_last_y = pos.y
		_last_time = now
	return scrolling


func release() -> void:
	if not scrolling:
		_velocity = 0.0
	scrolling = false


## Her karede çağır; offset değiştiyse true
func step(delta: float) -> bool:
	if scrolling or absf(_velocity) < 5.0:
		return false
	var before := offset
	offset = clampf(offset + _velocity * delta, 0.0, max_offset)
	_velocity *= pow(0.02, delta)
	if offset <= 0.0 or offset >= max_offset:
		_velocity = 0.0
	return offset != before
