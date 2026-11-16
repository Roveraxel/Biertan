## .NET's seeded System.Random (Knuth subtractive), so layouts seeded in the Unity build grow the same here.
class_name NetRandom
extends RefCounted

const MBIG := 2147483647
var _a: Array[int] = []
var _i := 0
var _ip := 21

func _init(seed_value: int = 1) -> void:
	_a.resize(56)
	_a.fill(0)
	var sub: int = MBIG if seed_value == -2147483648 else absi(seed_value)
	var mj: int = 161803398 - sub
	_a[55] = mj
	var mk := 1
	for i in range(1, 55):
		var ii := (21 * i) % 55
		_a[ii] = mk
		mk = _w(mj - mk)
		if mk < 0: mk += MBIG
		mj = _a[ii]
	for _k in range(1, 5):
		for i in range(1, 56):
			_a[i] = _w(_a[i] - _a[1 + (i + 30) % 55])
			if _a[i] < 0: _a[i] += MBIG

## 32-bit wraparound, as C# ints overflow.
static func _w(v: int) -> int:
	return ((v + 2147483648) & 0xffffffff) - 2147483648

func _sample() -> int:
	var li := _i + 1
	if li >= 56: li = 1
	var lp := _ip + 1
	if lp >= 56: lp = 1
	var r := _w(_a[li] - _a[lp])
	if r == MBIG: r -= 1
	if r < 0: r += MBIG
	_a[li] = r
	_i = li
	_ip = lp
	return r

## 0 <= x < 1
func f() -> float:
	return _sample() * (1.0 / MBIG)

## a <= x < b
func range_f(a: float, b: float) -> float:
	return a + f() * (b - a)

## 0 <= n < max_value
func i(max_value: int) -> int:
	return int(f() * max_value)
