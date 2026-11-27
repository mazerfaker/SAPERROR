extends Node
## Deterministic procedural SFX and approved menu click; long periodic hum.
const Atmosphere = preload("res://scripts/audio/atmosphere.gd")
const RATE: int = 22050
const HUM_RATE: int = 48000
const HUM_PERIOD_SECONDS: int = 2
const HUM_COPIES: int = 30
const ADMIN_INTRO_PATH := "res://assets/audio/dragon-studio-glitch-effect-1-397982.mp3"
const ADMIN_INTRO_SHA := "760b72bdaad71f83350e2ef3a9d037daf58f44855a05a6cce25d990f1ffb888a"
const MENU_CLICK_PATH := "res://assets/audio/finntastico-old-computer-click-152513.mp3"
const MENU_CLICK_SHA := "7ebe2a698a203d0682cfdf0d13c2a352bae46c69d989259698d9a87787a2d034"
const EXTRA := {
	"purchase":[0.18,430.0,820.0,0.16,0.03,2],
	"module":[0.30,180.0,640.0,0.18,0.05,3],
	"repair":[0.25,240.0,480.0,0.18,0.03,2],
	"shield":[0.28,330.0,160.0,0.19,0.07,2],
	"reroll":[0.21,520.0,240.0,0.14,0.07,4],
	"scanner":[0.26,480.0,760.0,0.16,0.025,3],
	"rewind":[0.32,720.0,160.0,0.19,0.045,4],
	"cleanse":[0.36,210.0,540.0,0.18,0.06,2],
	"portal":[0.30,390.0,600.0,0.16,0.055,4],
	"rule":[0.13,310.0,460.0,0.15,0.04,2],
	"archive":[0.46,260.0,780.0,0.19,0.02,3],
	"phase":[0.42,120.0,360.0,0.20,0.07,3],
	"anomaly":[0.32,165.0,95.0,0.18,0.08,3]
}
const EVENTS := ["key","reveal","flood","flag","unflag","fault","win","loss","invalid","boot","shutdown","k30","hum","purchase","module","repair","shield","reroll","scanner","rewind","cleanse","portal","rule","archive","phase","anomaly"]
const VOICE_COUNT: int=6
var sounds: Dictionary = {}
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var voice_priorities: Array[int]=[]
var master_level: float=1.0
var last_event: String=""
var dropped_events: int=0
var sfx_level: float = 0.55
var hum_level: float = 0.28
var enabled: bool = true
var music_level: float=Atmosphere.DEFAULT_LEVEL
var music: Atmosphere

static func synth(kind: String) -> AudioStreamWAV:
	if EXTRA.has(kind): return synth_extra(kind)
	var duration: float = 0.10
	match kind:
		"key": duration = 0.065
		"reveal": duration = 0.11
		"flood": duration = 0.23
		"flag","unflag": duration = 0.14
		"fault": duration = 0.48
		"win","loss": duration = 0.72
		"invalid": duration = 0.18
		"boot": duration = 0.52
		"shutdown": duration = 0.60
		"k30": duration = 0.42
		"hum": duration = 2.0
	var rate: int = HUM_RATE if kind=="hum" else RATE
	var count: int = roundi(duration * rate)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17301
	var lp: float = 0.0
	for i in range(count):
		var t: float = float(i) / rate
		var x: float = t / duration
		var noise: float = rng.randf_range(-1.0,1.0)
		lp = lerpf(lp,noise,0.12)
		var env: float = minf(1.0,t*280.0)*pow(maxf(0.0,1.0-x),2.0)
		var sample: float = 0.0
		match kind:
			"hum":
				sample = 0.13*sin(TAU*50.0*t)+0.065*sin(TAU*100.0*t)+0.026*sin(TAU*150.0*t)+0.013*sin(TAU*350.0*t)
				sample *= 0.88+0.12*sin(TAU*1.5*t)
			"key":
				sample = env*(0.24*noise+0.40*lp+0.19*sin(TAU*240.0*t))
			"reveal":
				sample = env*(0.32*sin(TAU*(620.0*t-700.0*t*t))+0.13*noise)
			"flood":
				var step_id: float = floor(t*30.0)
				var pulse: float = exp(-5.0*fposmod(t*30.0,1.0))
				sample = env*pulse*(0.32*sin(TAU*(380.0+step_id*90.0)*t)+0.08*lp)
			"flag","unflag":
				var freq: float = 780.0 if kind == "flag" else 420.0
				sample = env*(0.34*sin(TAU*freq*t)+0.09*sin(TAU*freq*2.0*t))
			"fault":
				sample = env*(0.35*lp+0.18*noise+0.25*sin(TAU*(95.0*t-42.0*t*t)))
			"win","loss":
				var notes: PackedFloat32Array = PackedFloat32Array([440.0,554.0,659.0,880.0]) if kind == "win" else PackedFloat32Array([330.0,247.0,165.0,110.0])
				var n: int = mini(3,int(x*4.0))
				var local: float = fposmod(x*4.0,1.0)
				var note_env: float = minf(1.0,local*20.0)*pow(1.0-local,0.9)
				sample = note_env*0.27*(sin(TAU*notes[n]*t)+0.15*sin(TAU*notes[n]*2.0*t))
			"invalid":
				sample = env*(0.22*sin(TAU*155.0*t)+0.12*sin(TAU*211.0*t))
			"boot":
				sample = env*(0.22*sin(TAU*(100.0*t+430.0*t*t))+0.10*lp)
			"shutdown":
				sample = env*(0.24*sin(TAU*(520.0*t-350.0*t*t))+0.12*lp)
			"k30":
				var note: float = 330.0 if t<0.10 else (660.0 if t<0.22 else 990.0)
				var pulse: float = exp(-3.0*fposmod(t*10.0,1.0))
				sample = env*pulse*(0.32*sin(TAU*note*t)+0.10*sin(TAU*note*2.0*t)+0.06*lp)
		pcm.encode_s16(i*2,roundi(clampf(sample,-0.9,0.9)*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	if kind == "hum":
		# 2 seconds is an exact common period of all oscillator frequencies.
		# Repeat the same phase-locked samples in memory so the audio backend
		# only wraps once per minute, with no stop/restart or silence at joins.
		var cycle: PackedByteArray = pcm.duplicate()
		for _i in range(1,HUM_COPIES): pcm.append_array(cycle)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count*HUM_COPIES
	stream.data = pcm
	return stream

# Original, short, gently windowed mechanical/tonal signals.
static func synth_extra(kind: String) -> AudioStreamWAV:
	if not EXTRA.has(kind): return null
	var spec: Array=EXTRA[kind]
	var duration: float=float(spec[0])
	var count: int=roundi(duration*RATE)
	var pcm:=PackedByteArray()
	pcm.resize(count*2)
	var rng:=RandomNumberGenerator.new()
	rng.seed=17301+EVENTS.find(kind)*97
	var low: float=0.0
	for i in range(count):
		var t: float=float(i)/RATE
		var x: float=float(i)/float(count-1)
		var f0: float=float(spec[1])
		var f1: float=float(spec[2])
		var phase: float=TAU*(f0*t+(f1-f0)*t*t/(2.0*duration))
		low=lerpf(low,rng.randf_range(-1.0,1.0),0.14)
		var pulse: float=0.65+0.35*cos(TAU*float(spec[5])*x)
		var envelope: float=smoothstep(0.0,0.018,x)*(1.0-smoothstep(0.55,1.0,x))
		var sample: float=envelope*pulse*(float(spec[3])*(sin(phase)+0.22*sin(phase*2.0))+float(spec[4])*low)
		pcm.encode_s16(i*2,roundi(clampf(sample,-0.35,0.35)*32767.0))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=RATE
	stream.stereo=false
	stream.data=pcm
	return stream

static func priority(kind: String) -> int:
	if kind in ["admin_intro","shutdown","win","loss","k30","archive","phase"]: return 3
	if kind in ["fault","anomaly","shield","cleanse","rewind","boot"]: return 2
	if kind in ["menu_click","key","flag","unflag","invalid"]: return 0
	return 1

# Prefer a free voice; never cut a sound of equal or higher importance.
static func pick_voice(busy: Array[bool], priorities: Array[int], start: int, incoming: int) -> int:
	if busy.is_empty() or busy.size()!=priorities.size(): return -1
	var weakest: int=-1
	for offset in range(busy.size()):
		var i: int=posmod(start+offset,busy.size())
		if not busy[i]: return i
		if priorities[i]<incoming and (weakest<0 or priorities[i]<priorities[weakest]): weakest=i
	return weakest

static func gain_db(channel: float,master: float,active: bool) -> float:
	return linear_to_db(maxf(0.0001,clampf(channel,0.0,1.0)*clampf(master,0.0,1.0))) if active else -80.0

static func button_event(screen: String) -> String:
	return "menu_click" if screen=="menu" else "key"

static func menu_click_stream() -> AudioStreamMP3:
	if not ResourceLoader.exists(MENU_CLICK_PATH): return null
	var source := load(MENU_CLICK_PATH) as AudioStreamMP3
	if source!=null: source.loop = false
	return source

static func admin_intro_stream() -> AudioStreamMP3:
	if not ResourceLoader.exists(ADMIN_INTRO_PATH): return null
	var source := load(ADMIN_INTRO_PATH) as AudioStreamMP3
	if source!=null: source.loop=false
	return source

func _ready() -> void:
	music=Atmosphere.new()
	music.set_levels(music_level,enabled)
	music.set_master(master_level)
	add_child(music)
	if DisplayServer.get_name() == "headless": return
	for kind in EVENTS:
		sounds[kind] = synth(kind)
	var menu_click := menu_click_stream()
	# Source checkout stays usable while original asset is awaiting upload.
	# The old procedural click is only a fallback, never a replacement asset.
	sounds["menu_click"] = menu_click if menu_click!=null else sounds["key"]
	var intro := admin_intro_stream()
	if intro!=null: sounds["admin_intro"]=intro
	ambience = AudioStreamPlayer.new()
	ambience.stream = sounds["hum"]
	add_child(ambience)
	for i in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
		voice_priorities.append(-1)
	_apply_levels()
	play_event("boot")

func set_levels(sfx: float, hum: float, active: bool) -> void:
	sfx_level = clampf(sfx,0.0,1.0)
	hum_level = clampf(hum,0.0,1.0)
	enabled = active
	if is_instance_valid(music): music.set_levels(music_level,enabled)
	_apply_levels()

func _apply_levels() -> void:
	if not is_instance_valid(ambience): return
	ambience.volume_db = gain_db(hum_level,master_level,enabled)
	for voice in voices:
		voice.volume_db = gain_db(sfx_level,master_level,enabled)
		if not enabled or sfx_level <= 0.0: voice.stop()
	if not enabled or hum_level <= 0.0:
		ambience.stop()
	elif not ambience.playing:
		ambience.play()

func play_event(kind: String) -> void:
	if kind not in EVENTS and kind not in ["menu_click","admin_intro"]: return
	last_event=kind
	if not enabled or sfx_level<=0.0 or master_level<=0.0 or voices.is_empty() or not sounds.has(kind): return
	var busy: Array[bool]=[]
	for voice in voices: busy.append(voice.playing)
	var selected: int=pick_voice(busy,voice_priorities,next_voice,priority(kind))
	if selected<0:
		dropped_events+=1
		return
	var voice: AudioStreamPlayer=voices[selected]
	next_voice=(selected+1)%voices.size()
	voice_priorities[selected]=priority(kind)
	if voice.playing: voice.stop()
	voice.stream=sounds[kind]
	voice.play()

func fade_hum(factor: float) -> void:
	if is_instance_valid(ambience) and enabled:
		ambience.volume_db = gain_db(hum_level*clampf(factor,0.0,1.0),master_level,enabled)

func set_music_level(value: float) -> void:
	music_level=clampf(value,0.0,1.0)
	if is_instance_valid(music): music.set_levels(music_level,enabled)
func select_music(id: String) -> void:
	if is_instance_valid(music): music.select(id)
func fade_music(factor: float) -> void:
	if is_instance_valid(music): music.fade_power(factor)

func set_master(value: float) -> void:
	master_level=clampf(value,0.0,1.0)
	if is_instance_valid(music): music.set_master(master_level)
	_apply_levels()
func effective_sfx() -> float:
	return sfx_level*master_level if enabled else 0.0
