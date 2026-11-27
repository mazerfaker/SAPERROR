extends RefCounted
## Direct port of approved animation.js. Times are milliseconds.
const CUE_TIMES := [0,55,132,170,238,285,450,485]
const CUE_ON := [false,true,false,true,false,true,false,true]
var time_ms: float = 0.0
var level: int = 3
var target: int = 3
var next_step: float = 0.0
var next_episode: float = 0.0
var episode_start: float = -1.0
var serial: int = 0
var steps: int = 0
var rng := RandomNumberGenerator.new()
var fixture_seed: int = 0
func start(seed_value: int = 0) -> void:
	rng.randomize()
	fixture_seed = seed_value
	time_ms = 0.0
	level = 3
	target = 3
	episode_start = -1.0
	serial = 0
	steps = 0
	next_step = _range(800.0,3000.0)
	next_episode = _range(20000.0,30000.0)
func _random() -> float:
	if fixture_seed>0:
		fixture_seed = (fixture_seed*16807)%2147483647
		return float(fixture_seed)/2147483647.0
	return minf(rng.randf(),0.999999999)
func _range(low: float, high: float) -> float:
	return low+(high-low)*_random()
static func lamp_at(ms: float) -> bool:
	if ms<0.0 or ms>=500.0: return true
	var on: bool = true
	for i in range(CUE_TIMES.size()):
		if ms<float(CUE_TIMES[i]): break
		on = CUE_ON[i]
	return on
func lamp_on() -> bool:
	return lamp_at(time_ms-episode_start) if episode_start>=0.0 else true
func tick(now_ms: float) -> void:
	if now_ms<time_ms: return
	while next_step<=now_ms:
		var at: float = next_step
		if level==target:
			var n: int = floori(_random()*6.0)
			target = n+1 if n>=level else n
		level += 1 if target>level else -1
		steps += 1
		next_step = at+(_range(800.0,3000.0) if level==target else _range(120.0,300.0))
	while next_episode<=now_ms:
		var at: float = next_episode
		episode_start = at
		serial += 1
		next_episode = at+_range(20000.0,30000.0)
	if episode_start>=0.0 and now_ms>=episode_start+500.0: episode_start = -1.0
	time_ms = now_ms
