extends Node
## Original deterministic procedural PCM, no external audio assets.
const RATE: int = 22050
const EVENTS := ["key","reveal","flood","flag","unflag","fault","win","loss","invalid","boot","hum"]
var sounds: Dictionary = {}
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var sfx_level: float = 0.55
var hum_level: float = 0.28
var enabled: bool = true

static func synth(kind: String) -> AudioStreamWAV:
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
		"hum": duration = 2.0
	var count: int = roundi(duration * RATE)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17301
	var lp: float = 0.0
	for i in range(count):
		var t: float = float(i) / RATE
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
				var notes: Array[float] = [440.0,554.0,659.0,880.0] if kind == "win" else [330.0,247.0,165.0,110.0]
				var n: int = mini(3,int(x*4.0))
				var local: float = fposmod(x*4.0,1.0)
				var note_env: float = minf(1.0,local*20.0)*pow(1.0-local,0.9)
				sample = note_env*0.27*(sin(TAU*notes[n]*t)+0.15*sin(TAU*notes[n]*2.0*t))
			"invalid":
				sample = env*(0.22*sin(TAU*155.0*t)+0.12*sin(TAU*211.0*t))
			"boot":
				sample = env*(0.22*sin(TAU*(100.0*t+430.0*t*t))+0.10*lp)
		pcm.encode_s16(i*2,roundi(clampf(sample,-0.9,0.9)*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = pcm
	if kind == "hum":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream

func _ready() -> void:
	if DisplayServer.get_name() == "headless": return
	for kind in EVENTS:
		sounds[kind] = synth(kind)
	ambience = AudioStreamPlayer.new()
	ambience.stream = sounds["hum"]
	add_child(ambience)
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	_apply_levels()
	ambience.play()
	play_event("boot")

func set_levels(sfx: float, hum: float, active: bool) -> void:
	sfx_level = clampf(sfx,0.0,1.0)
	hum_level = clampf(hum,0.0,1.0)
	enabled = active
	_apply_levels()

func _apply_levels() -> void:
	if not is_instance_valid(ambience): return
	ambience.volume_db = linear_to_db(maxf(hum_level,0.0001)) if enabled else -80.0
	for voice in voices:
		voice.volume_db = linear_to_db(maxf(sfx_level,0.0001)) if enabled else -80.0
		if not enabled or sfx_level <= 0.0: voice.stop()
	if not enabled or hum_level <= 0.0:
		ambience.stop()
	elif not ambience.playing:
		ambience.play()

func play_event(kind: String) -> void:
	if not enabled or sfx_level <= 0.0 or voices.is_empty() or not sounds.has(kind): return
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stop()
	voice.stream = sounds[kind]
	voice.play()
