extends RefCounted
enum Phase { BOOT, READY, SHUTDOWN, OFF }
const POWER_TIME_SCALE: float=2.0/3.0
const BOOT_LINE_TIME: float=0.16*POWER_TIME_SCALE
const BOOT_OPEN_TIME: float=0.90*POWER_TIME_SCALE
const BIOS_TIME: float=5.00*POWER_TIME_SCALE
const BIOS_HOLD: float=0.50*POWER_TIME_SCALE
const BOOT_TIME: float=BOOT_OPEN_TIME+BIOS_TIME+BIOS_HOLD
const SHUTDOWN_CLOSE_TIME: float=0.85*POWER_TIME_SCALE
const SHUTDOWN_LINE_HOLD: float=0.16*POWER_TIME_SCALE
const SHUTDOWN_TIME: float=1.20*POWER_TIME_SCALE
var phase: int = Phase.BOOT
var elapsed: float = 0.0
# CRT filters and power lifecycle are independent; explicit accessibility choices win.
static func animation_allowed(headless: bool, _reduced: bool, _clear: bool) -> bool:
	return not headless
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
func bios_started() -> bool:
	return phase==Phase.BOOT and elapsed>=BOOT_OPEN_TIME
func bios_progress() -> float:
	if phase==Phase.BOOT: return clampf((elapsed-BOOT_OPEN_TIME)/BIOS_TIME,0.0,1.0)
	return 1.0
func beam() -> float:
	if phase==Phase.BOOT: return lerpf(0.004,1.0,smoothstep(BOOT_LINE_TIME,BOOT_OPEN_TIME,elapsed))
	if phase==Phase.SHUTDOWN: return lerpf(1.0,0.004,smoothstep(0.0,SHUTDOWN_CLOSE_TIME,elapsed))
	return 0.0 if phase==Phase.OFF else 1.0
func power() -> float:
	# No whole-screen opacity fade. Only the last narrow phosphor line dies out.
	if phase==Phase.BOOT: return 0.0 if elapsed<=0.0 else 1.0
	if phase==Phase.SHUTDOWN: return 1.0 if elapsed<SHUTDOWN_CLOSE_TIME+SHUTDOWN_LINE_HOLD else 1.0-smoothstep(SHUTDOWN_CLOSE_TIME+SHUTDOWN_LINE_HOLD,SHUTDOWN_TIME,elapsed)
	return 0.0 if phase==Phase.OFF else 1.0
func line_strength() -> float:
	if phase==Phase.BOOT: return power()*(1.0-beam())
	if phase==Phase.SHUTDOWN: return power()*(1.0-beam())
	return 0.0
