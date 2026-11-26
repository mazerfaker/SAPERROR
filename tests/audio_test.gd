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
		check(stream.mix_rate == Audio.RATE and not stream.stereo,"PCM format "+kind)
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
			check(absi(data.decode_s16(0)-data.decode_s16(data.size()-2)) < 3000,"hum seam")
		else:
			check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,"one-shot "+kind)
	var player := Audio.new()
	root.add_child(player)
	player.set_levels(-1.0,2.0,false)
	check(player.sfx_level == 0.0 and player.hum_level == 1.0 and not player.enabled,"level clamp and mute")
	player.play_event("fault")
	player.queue_free()
	print("AUDIO_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
