extends SceneTree
# Real 72-second native playback/render smoke, not a 72-hour hardware soak.
const Scene=preload("res://scenes/game/gameplay.tscn")
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		if failures<=20: printerr("NATIVE_SOAK FAIL: ",message)
func _initialize() -> void:
	create_timer(120.0).timeout.connect(func(): printerr("NATIVE_SOAK timeout"); quit(1))
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("NATIVE_SOAK requires native renderer")
		quit(1)
		return
	var game=Scene.instantiate()
	root.add_child(game)
	game._finish_boot()
	var env=game.live
	var audio=game.ui.audio
	check(is_instance_valid(env) and is_instance_valid(audio.ambience) and is_instance_valid(audio.music.stream_player),"native resources")
	if failures>0:
		game.queue_free()
		quit(1)
		return
	audio.set_levels(0.55,0.28,true)
	audio.set_music_level(0.25)
	audio.select_music("act_boot")
	var hum_id: int=audio.ambience.get_instance_id()
	var music_id: int=audio.music.stream_player.get_instance_id()
	var lamp_id: int=env.player.get_instance_id()
	var tex: Dictionary=env.textures.duplicate()
	await create_timer(1.5).timeout
	check(audio.ambience.playing and audio.music.stream_player.playing,"native playback begins")
	var prev_hum: float=audio.ambience.get_playback_position()
	var prev_music: float=audio.music.stream_player.get_playback_position()
	var hum_wraps: int=0
	var music_wraps: int=0
	var samples: int=0
	var prior_clock: float=env.clock.time_ms
	var deadline: int=Time.get_ticks_msec()+72000
	while Time.get_ticks_msec()<deadline:
		await create_timer(0.5).timeout
		var hum: float=audio.ambience.get_playback_position()
		var music: float=audio.music.stream_player.get_playback_position()
		if hum<prev_hum-10.0: hum_wraps+=1
		if music<prev_music-10.0: music_wraps+=1
		prev_hum=hum
		prev_music=music
		samples+=1
		check(audio.ambience.playing and audio.music.stream_player.playing,"continuous loop playback")
		check(audio.music.current=="act_boot" and audio.music.requested=="act_boot","same selected cue")
		check(env.textures==tex and env.player.get_instance_id()==lamp_id and env.drawn_level in range(7),"live frame resources")
		check(env.clock.time_ms>prior_clock,"live clock advances")
		prior_clock=env.clock.time_ms
		if samples%20==0: print("NATIVE_SOAK_SAMPLE elapsed_ms=",72000-maxi(0,deadline-Time.get_ticks_msec())," fps=",Engine.get_frames_per_second()," engine_memory=",Performance.get_monitor(Performance.MEMORY_STATIC)," video_memory=",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)," nodes=",get_node_count()," hum_wraps=",hum_wraps," music_wraps=",music_wraps)
	check(hum_wraps>=1 and music_wraps>=2,"actual playback head wrapped")
	check(audio.ambience.get_instance_id()==hum_id and audio.music.stream_player.get_instance_id()==music_id,"same audio players")
	check(env.clock.steps>0 and env.clock.serial>0,"live indicators and lamp episodes")
	check(audio.music.cache.size()==1,"single cue stays cached")
	print("NATIVE_SOAK checks=",checks," failures=",failures," actual_seconds=72 hum_wraps=",hum_wraps," music_wraps=",music_wraps," samples=",samples)
	game.queue_free()
	quit(0 if failures==0 else 1)
