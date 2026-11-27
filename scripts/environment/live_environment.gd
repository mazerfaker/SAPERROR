extends Node2D
## All images are the approved assets. One draw list, one player, one scheduler.
const Clock = preload("res://scripts/environment/environment_clock.gd")
const ROOT := "res://assets/live/"
const NATIVE := Vector2(1920,1080)
const AUDIO_GAIN := 0.1
var clock := Clock.new()
var layers: Dictionary = {}
var textures: Dictionary = {}
var high_frames: Array[Texture2D] = []
var post_position := Vector2(1440,653)
var player: AudioStreamPlayer
var stream: AudioStream
var ready_assets: bool = false
var drawn_level: int = 3
var drawn_lamp: bool = true
var seen_episode: int = 0
var audio_episode: int = 0
var audio_ms: float = 0.0
var audio_enabled: bool = true
var sfx_level: float = 1.0
var last_audio_db: float=-1000.0
var audio_gain_writes: int=0
var minimized: bool = false
var automatic: bool = true
func setup(seed_value: int = 0) -> bool:
	if ready_assets: return true
	var path: String = ROOT+"config.json"
	if not FileAccess.file_exists(path): return false
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary: return false
	var cfg: Dictionary = raw
	if int(cfg.get("width",0))!=1920 or int(cfg.get("height",0))!=1080 or cfg.get("defaultMode","")!="high": return false
	layers = cfg["layers"]
	var device: Dictionary = cfg["post"]["device"]
	post_position = Vector2(device["x"],device["y"])
	for key in layers:
		var layer: Dictionary = layers[key]
		var tex: Texture2D = _load_texture(layer["file"])
		if tex==null or tex.get_size()!=Vector2(layer["width"],layer["height"]): return false
	for file in device["files"]["high"]:
		var tex: Texture2D = _load_texture(file)
		if tex==null or tex.get_size()!=Vector2(device["width"],device["height"]): return false
		high_frames.append(tex)
	if high_frames.size()!=7 or layers.size()!=14: return false
	var audio_path: String = ROOT+str(cfg["audio"]["file"])
	if not ResourceLoader.exists(audio_path): return false
	stream = load(audio_path) as AudioStream
	if stream==null or absf(stream.get_length()-0.5)>0.001: return false
	clock.start(seed_value)
	ready_assets = true
	return true
func _load_texture(file: String) -> Texture2D:
	if textures.has(file): return textures[file]
	var path: String = ROOT+file
	if not ResourceLoader.exists(path): return null
	var tex: Texture2D = load(path) as Texture2D
	if tex!=null: textures[file] = tex
	return tex
func _ready() -> void:
	if not ready_assets: return
	player = AudioStreamPlayer.new()
	player.name = "LampBallast"
	player.stream = stream
	player.max_polyphony = 1
	add_child(player)
	set_audio_settings(sfx_level,audio_enabled)
	queue_redraw()
func _draw_layer(key: String) -> void:
	var layer: Dictionary = layers[key]
	var pos := Vector2(layer["x"],layer["y"])
	draw_texture(textures[layer["file"]],pos,Color(1,1,1,float(layer["opacity"])))
func _draw() -> void:
	if not ready_assets: return
	_draw_layer("base")
	if not drawn_lamp: _draw_layer("lamp_off")
	for i in range(1,7):
		_draw_layer(str(i)+("_on" if i<=drawn_level else "_off"))
	draw_texture(high_frames[drawn_level],post_position)
func set_audio_settings(level: float, enabled: bool) -> void:
	sfx_level = clampf(level,0.0,1.0)
	audio_enabled = enabled
	if is_instance_valid(player):
		var gain: float = AUDIO_GAIN*sfx_level if audio_enabled else 0.0
		var db: float=linear_to_db(gain) if gain>0.0 else -80.0
		if last_audio_db!=db:
			player.volume_db=db
			last_audio_db=db
			audio_gain_writes+=1
func _set_visual(level: int, lamp: bool) -> void:
	if level!=drawn_level or lamp!=drawn_lamp:
		drawn_level = level
		drawn_lamp = lamp
		queue_redraw()
func advance_virtual(delta: float) -> void:
	# QA uses accelerated virtual time; never starts real audio.
	clock.tick(clock.time_ms+maxf(0.0,delta)*1000.0)
	_set_visual(clock.level,clock.lamp_on())
func _process(delta: float) -> void:
	if not ready_assets or not automatic: return
	var hidden: bool = DisplayServer.get_name()!="headless" and get_window().mode==Window.MODE_MINIMIZED
	if hidden!=minimized:
		minimized = hidden
		player.stream_paused = hidden
	if minimized: return
	clock.tick(clock.time_ms+clampf(delta,0.0,0.1)*1000.0)
	if clock.episode_start>=0.0 and clock.serial!=seen_episode:
		seen_episode = clock.serial
		var offset: float = (clock.time_ms-clock.episode_start)/1000.0
		if DisplayServer.get_name()!="headless" and offset<stream.get_length():
			player.play(offset)
			audio_episode = seen_episode
			audio_ms = offset*1000.0
	var lamp: bool = clock.lamp_on()
	if audio_episode==clock.serial and audio_episode>0:
		if player.playing:
			# Align visible cues with the audible playback head, compensating for mixer and output latency.
			var heard: float = (player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())*1000.0
			audio_ms = maxf(audio_ms,clampf(heard,0.0,500.0))
			lamp = Clock.lamp_at(audio_ms)
		else:
			lamp = true
			audio_episode = 0
	_set_visual(clock.level,lamp)
