extends SceneTree
const Audio = preload("res://scripts/audio/terminal_audio.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		printerr("FAIL: audio QA watchdog timeout")
		quit(1))
	call_deferred("run")
func run() -> void:
	for kind in Audio.EVENTS:
		var stream: AudioStreamWAV = Audio.synth(kind)
		check(stream != null,"synthesis returns stream "+kind)
		if stream == null: continue
		check(stream.mix_rate == (Audio.HUM_RATE if kind=="hum" else Audio.RATE) and not stream.stereo,"PCM format "+kind)
		check(stream.data.size() > 0 and stream.data.size()%2 == 0,"PCM length "+kind)
		var peak: int = 0
		var data: PackedByteArray = stream.data
		for i in range(0,data.size(),2):
			peak = maxi(peak,absi(data.decode_s16(i)))
		check(peak > 100 and peak < 32767,"non-silent unclipped PCM "+kind)
		var repeat: AudioStreamWAV = Audio.synth(kind)
		check(repeat != null and repeat.data == data,"deterministic PCM "+kind)
		if kind == "hum":
			check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end == data.size()/2,"hum loop")
			var period_bytes: int = Audio.HUM_RATE*Audio.HUM_PERIOD_SECONDS*2
			check(data.size()==period_bytes*Audio.HUM_COPIES and is_equal_approx(stream.get_length(),60.0),"60 second hum")
			var seam: int = data.decode_s16(0)-data.decode_s16(data.size()-2)
			var first_slope: int = data.decode_s16(2)-data.decode_s16(0)
			var last_slope: int = data.decode_s16(data.size()-2)-data.decode_s16(data.size()-4)
			check(absi(seam)<150 and absi(first_slope-seam)<5 and absi(last_slope-seam)<5,"phase and derivative continuous at wrap")
			var period: PackedByteArray = data.slice(0,period_bytes)
			for i in range(1,Audio.HUM_COPIES):
				check(data.slice(i*period_bytes,(i+1)*period_bytes)==period,"phase locked repeated PCM")
			check(data.decode_s16(period_bytes)-data.decode_s16(period_bytes-2)==seam,"internal and external join equal")
		else:
			check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,"one-shot "+kind)
	check(Audio.button_event("menu")=="menu_click","menu uses dedicated click")
	for screen in ["game","settings","audio","shop","profiles","help"]:
		check(Audio.button_event(screen)=="menu_click","shared UI sound "+screen)
	var menu_click := Audio.menu_click_stream()
	if FileAccess.file_exists(Audio.MENU_CLICK_PATH):
		check(FileAccess.get_sha256(Audio.MENU_CLICK_PATH)==Audio.MENU_CLICK_SHA,"exact original menu MP3 bytes")
		check(menu_click!=null,"menu MP3 loads")
		if menu_click!=null:
			check(not menu_click.loop and menu_click.get_length()>0.1 and menu_click.get_length()<0.3,"short one-shot menu click")
	else:
		print("MENU_CLICK_ASSET_PENDING: original MP3 upload required; procedural fallback only")
	var intro := Audio.admin_intro_stream()
	if FileAccess.file_exists(Audio.ADMIN_INTRO_PATH):
		check(FileAccess.get_sha256(Audio.ADMIN_INTRO_PATH)==Audio.ADMIN_INTRO_SHA,"original ADMIN intro bytes")
		check(intro!=null,"ADMIN intro imports")
		if intro!=null: check(not intro.loop and intro.get_length()>2.5 and intro.get_length()<2.8,"ADMIN one-shot duration")
	else: check(false,"approved ADMIN intro asset required")
	var player := Audio.new()
	root.add_child(player)
	player.set_levels(-1.0,2.0,false)
	check(player.sfx_level == 0.0 and player.hum_level == 1.0 and not player.enabled,"level clamp and mute")
	player.play_event("fault")
	player.queue_free()
	print("AUDIO_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
