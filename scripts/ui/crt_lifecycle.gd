extends RefCounted
enum Phase { BOOT, READY, SHUTDOWN, OFF }
const BOOT_TIME: float = 2.4
const SHUTDOWN_TIME: float = 0.65
var phase: int = Phase.BOOT
var elapsed: float = 0.0
# CRT filters and power lifecycle are independent; explicit accessibility choices win.
static func animation_allowed(headless: bool, reduced: bool, clear: bool) -> bool:
	return not headless and not reduced and not clear
func begin_boot() -> void:
	if phase!=Phase.READY: return
	phase=Phase.BOOT
	elapsed=0.0
func advance(delta: float) -> void:
	elapsed += maxf(delta,0.0)
	if phase == Phase.BOOT and elapsed >= BOOT_TIME:
		skip_boot()
	elif phase == Phase.SHUTDOWN and elapsed >= SHUTDOWN_TIME:
		phase = Phase.OFF
func skip_boot() -> void:
	if phase != Phase.BOOT: return
	phase = Phase.READY
	elapsed = 0.0
func begin_shutdown() -> void:
	if phase != Phase.READY: return
	phase = Phase.SHUTDOWN
	elapsed = 0.0
func accepts_input() -> bool:
	return phase == Phase.READY
func progress() -> float:
	if phase == Phase.BOOT: return clampf(elapsed/BOOT_TIME,0.0,1.0)
	if phase == Phase.SHUTDOWN: return clampf(elapsed/SHUTDOWN_TIME,0.0,1.0)
	return 1.0
func beam() -> float:
	if phase == Phase.BOOT: return lerpf(0.005,1.0,smoothstep(0.0,0.45,elapsed))
	if phase == Phase.SHUTDOWN: return lerpf(1.0,0.003,smoothstep(0.0,0.52,elapsed))
	return 0.0 if phase == Phase.OFF else 1.0
func power() -> float:
	if phase == Phase.BOOT: return smoothstep(0.0,0.65,elapsed)
	if phase == Phase.SHUTDOWN: return 1.0-smoothstep(0.40,SHUTDOWN_TIME,elapsed)
	return 0.0 if phase == Phase.OFF else 1.0
