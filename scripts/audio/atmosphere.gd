extends Node
# Original tonal sound design. All oscillators have an exact 8-second period.
# The user-approved hum and SFX are separate and are never processed here.
const RATE: int=48000
const PERIOD: int=8
const COPIES: int=4
const DEFAULT_LEVEL: float=0.25
const FADE: float=0.45
const CACHE_LIMIT: int=3
# Integer Hz frequencies, integer modulation cycles per period, pulse depth.
const THEMES := {
	"act_boot":[55,110,165,1,0.10],
	"act_corruption":[58,87,123,3,0.24],
	"act_echo":[49,98,147,2,0.12],
	"act_admin":[46,69,93,4,0.26],
	"boss_watcher":[62,93,124,2,0.32],
	"boss_liar":[57,81,121,5,0.34],
	"boss_loop":[52,104,156,4,0.42],
	"boss_admin":[41,61,82,6,0.38],
	"end_shutdown":[44,66,88,1,0.08],
	"end_containment":[55,82,137,2,0.12],
	"end_rewrite":[65,98,130,1,0.15]
}
var level: float=DEFAULT_LEVEL
var master: float=1.0
var enabled: bool=true
var requested: String=""
var current: String=""
var gain: float=0.0
var power: float=1.0
var stream_player: AudioStreamPlayer
var cache: Dictionary={}
var cache_order: Array[String]=[]
var last_db: float=-80.0
var volume_writes: int=0
static func scene_theme(screen: String, story: bool, act: int, boss: String, ending: String, lab: String="") -> String:
	if screen=="ending_scene" or screen=="gallery_preview":
		var id: String="end_"+ending.to_lower()
		return id if THEMES.has(id) else ""
	if screen=="admin_intro": return "boss_admin"
	if screen=="campaign_boss" or screen=="challenge":
		var id: String="boss_"+(boss if screen=="campaign_boss" else lab).to_lower()
		if THEMES.has(id): return id
	if story and screen in ["campaign_intro","game","shop","campaign_route","campaign_archive","campaign_recovery","ending_choice","rewrite_trial"]:
		return ["act_boot","act_corruption","act_echo","act_admin"][clampi(act,0,3)]
	return ""
static func synth(id: String) -> AudioStreamWAV:
	if not THEMES.has(id): return null
	var spec: Array=THEMES[id]
	var count: int=RATE*PERIOD
	var pcm:=PackedByteArray()
	pcm.resize(count*2)
	var f0: float=float(spec[0])
	var f1: float=float(spec[1])
	var f2: float=float(spec[2])
	var cycles: float=float(spec[3])
	var depth: float=float(spec[4])
	for i in range(count):
		var t: float=float(i)/RATE
		var x: float=t/PERIOD
		var slow: float=sin(TAU*x)
		var pulse: float=0.5-0.5*cos(TAU*cycles*x)
		# Soft harmonic pad with continuous phase modulation, no abrupt gates.
		var sample: float=0.060*sin(TAU*f0*t+0.22*slow)
		sample+=0.038*sin(TAU*f1*t-0.30*slow)
		sample+=0.021*sin(TAU*f2*t+0.48*slow)
		sample+=0.012*sin(TAU*(f0*2.0)*t)
		sample*=1.0-depth+depth*pulse
		if id=="act_echo" or id=="end_rewrite":
			sample+=0.015*sin(TAU*(f2*2.0)*t)*(0.5+0.5*cos(TAU*x))
		elif id=="boss_liar" or id=="boss_admin":
			sample+=0.012*sin(TAU*(f1+2.0)*t)*(0.5+0.5*cos(TAU*2.0*x))
		pcm.encode_s16(i*2,roundi(clampf(sample,-0.20,0.20)*32767.0))
	var cycle: PackedByteArray=pcm.duplicate()
	for _i in range(1,COPIES): pcm.append_array(cycle)
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=RATE
	stream.stereo=false
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=count*COPIES
	stream.data=pcm
	return stream
func _ready() -> void:
	set_process(false)
	if DisplayServer.get_name()=="headless": return
	stream_player=AudioStreamPlayer.new()
	stream_player.name="NarrativeMusic"
	stream_player.volume_db=-80.0
	add_child(stream_player)
	set_process(true)
func select(id: String) -> void:
	requested=id if THEMES.has(id) else ""
func set_levels(value: float, active: bool) -> void:
	level=clampf(value,0.0,1.0)
	enabled=active
func fade_power(factor: float) -> void:
	power=clampf(factor,0.0,1.0)
func desired() -> String:
	return requested if enabled and level>0.0 and power>0.0 else ""
func _cached(id: String) -> AudioStreamWAV:
	if cache.has(id):
		cache_order.erase(id)
		cache_order.append(id)
		return cache[id] as AudioStreamWAV
	var stream:=synth(id)
	if stream==null: return null
	cache[id]=stream
	cache_order.append(id)
	while cache_order.size()>CACHE_LIMIT:
		cache.erase(cache_order.pop_front())
	return stream
func _process(delta: float) -> void:
	if not is_instance_valid(stream_player): return
	# Fade the old cue fully out before switching. Repeated requests for the
	# same cue never restart playback, including ADMIN phase transitions.
	var target: String=desired()
	if target!=current:
		gain=move_toward(gain,0.0,maxf(delta,0.0)/FADE)
		if gain<=0.0:
			_set_volume(-80.0)
			stream_player.stop()
			stream_player.stream=null
			current=""
			if not target.is_empty():
				var stream:=_cached(target)
				if stream!=null:
					stream_player.stream=stream
					current=target
					stream_player.play()
	else:
		gain=move_toward(gain,1.0 if not current.is_empty() else 0.0,maxf(delta,0.0)/FADE)
	var amplitude: float=gain*level*power*master if enabled else 0.0
	_set_volume(linear_to_db(maxf(0.0001,amplitude)))

func _set_volume(db: float) -> void:
	if last_db==db: return
	last_db=db
	stream_player.volume_db=db
	volume_writes+=1

func set_master(value: float) -> void:
	master=clampf(value,0.0,1.0)
