extends SceneTree
# Accelerated logical time is separate from hardware rendering/audio playback.
const Scene=preload("res://scenes/game/gameplay.tscn")
const Atmosphere=preload("res://scripts/audio/atmosphere.gd")
const Audio=preload("res://scripts/audio/terminal_audio.gd")
const Store=preload("res://scripts/save/session_store.gd")
const Clock=preload("res://scripts/environment/environment_clock.gd")
const Geometry=preload("res://scripts/ui/crt_geometry.gd")
const StyleBank=preload("res://scripts/ui/style_bank.gd")
const CHECKPOINTS: Array[int]=[5,10,24,48,72]
const STEPS_PER_HOUR: int=2160
const VIRTUAL_DELTA: float=100.0/60.0
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		if failures<=30: printerr("FAIL: ",message)
func _initialize() -> void:
	create_timer(180.0).timeout.connect(func(): printerr("SOAK timeout"); quit(1))
	call_deferred("run")
func run() -> void:
	var game=Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	var ui=game.ui
	var env=game.live
	check(is_instance_valid(env),"approved live environment loaded")
	if not is_instance_valid(env):
		game.queue_free()
		quit(1)
		return
	env.automatic=false
	env.clock.start(54321)
	var player_id: int=env.player.get_instance_id()
	var texture_refs: Dictionary=env.textures.duplicate()
	var frame_refs: Array[Texture2D]=env.high_frames.duplicate()
	var ui_id: int=ui.get_instance_id()
	var raster_id: int=game.raster.get_instance_id()
	var previous_steps: int=0
	var previous_episodes: int=0
	var ticks: int=0
	var min_level: int=6
	var max_level: int=0
	var lit: int=0
	var dark: int=0
	ui.reduced=true
	ui._start_profile(1)
	ui._show("menu")
	await process_frame
	await process_frame
	var menu_nodes: int=get_node_count()
	var menu_orphans: int=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var completed: int=0
	for hour in CHECKPOINTS:
		while ticks<hour*STEPS_PER_HOUR:
			env.advance_virtual(VIRTUAL_DELTA)
			ticks+=1
			var level: int=env.drawn_level
			min_level=mini(min_level,level)
			max_level=maxi(max_level,level)
			if env.drawn_lamp: lit+=1
			else: dark+=1
			check(level>=0 and level<env.high_frames.size() and env.high_frames[level]!=null,"valid frame")
			check(level==env.clock.level and env.drawn_lamp==env.clock.lamp_on(),"clock drives exact visual")
			check(env.clock.next_step>env.clock.time_ms and env.clock.next_episode>env.clock.time_ms,"next events scheduled")
		check(absf(env.clock.time_ms-float(hour)*3600000.0)<0.5,"virtual elapsed "+str(hour))
		check(env.clock.steps>previous_steps and env.clock.serial>previous_episodes,"animation continues "+str(hour))
		var elapsed_hours: int=hour-(0 if hour==CHECKPOINTS[0] else CHECKPOINTS[CHECKPOINTS.find(hour)-1])
		var episode_delta: int=env.clock.serial-previous_episodes
		check(episode_delta>=elapsed_hours*120-1 and episode_delta<=elapsed_hours*180+1,"approved 20-30s episode density")
		previous_steps=env.clock.steps
		previous_episodes=env.clock.serial
		check(min_level==0 and max_level==6 and lit>0 and dark>0,"all visual states reached")
		check(env.textures==texture_refs and env.high_frames==frame_refs,"texture identity unchanged")
		check(env.get_child_count()==1 and env.player.get_instance_id()==player_id,"one stable lamp player")
		# Exercise actual game progression, save validation, and page disposal.
		for run_step in range(12):
			ui._show("game")
			ui._reveal(0)
			check(ui.board!=null and not ui.board.finished(),"active generated sector")
			if ui.board==null or ui.board.finished(): break
			var snapshot: Dictionary=ui._snapshot_board()
			check(not Store.restore(snapshot).is_empty(),"live sector restorable")
			ui._begin_protocol()
			ui._process(4.0)
			ui._process(2.0)
			check(not ui.protocol_active and ui.screen=="game","protocol advances sector")
			if ui.protocol_active: break
			completed+=1
			for screen in ["settings","audio","help","performance","gallery","archives","challenges","classic","menu"]:
				var old_page: WeakRef=weakref(ui.page)
				ui._show(screen)
				await process_frame
				await process_frame
				check(old_page.get_ref()==null,"previous page released "+screen)
			check(get_node_count()==menu_nodes,"same menu node count after navigation")
			check(ui.style_bank.entries.size()<=StyleBank.LIMIT,"bounded UI cache")
		check(ui.get_instance_id()==ui_id and game.raster.get_instance_id()==raster_id,"persistent terminal/raster")
		check(game.display.position==Geometry.SCREEN.position and game.display.size==Geometry.SCREEN.size,"approved alignment retained")
		check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))<=menu_orphans,"no orphan-node growth at menu")
		print("SOAK_CHECKPOINT hours=",hour," steps=",env.clock.steps," lamp_episodes=",env.clock.serial," sectors=",completed," menu_nodes=",get_node_count()," orphans=",Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)," style_cache=",ui.style_bank.entries.size()," static_memory=",Performance.get_monitor(Performance.MEMORY_STATIC))
	check(ticks==155520 and completed==60,"72h and 60 sectors")
	# Headless verifies real PCM buffers and LRU resource ownership, not audible playback.
	var music:=Atmosphere.new()
	root.add_child(music)
	var first: AudioStreamWAV=music._cached("act_boot")
	var first_ref: WeakRef=weakref(first)
	check(music._cached("act_boot")==first,"cue reused")
	first=null
	for id in Atmosphere.THEMES:
		if id=="act_boot": continue
		var cue: AudioStreamWAV=music._cached(id)
		check(cue!=null and cue.loop_mode==AudioStreamWAV.LOOP_FORWARD and cue.loop_end==cue.data.size()/2,"native looping cue "+id)
		check(music.cache.size()<=Atmosphere.CACHE_LIMIT and music.cache_order.size()==music.cache.size(),"bounded music cache")
	check(first_ref.get_ref()==null,"evicted unused PCM released")
	var hum: AudioStreamWAV=Audio.synth("hum")
	check(hum.loop_mode==AudioStreamWAV.LOOP_FORWARD and is_equal_approx(hum.get_length(),60.0),"hum native loop")
	check(floori(72.0*3600.0/hum.get_length())==4320,"72h theoretical hum wraps")
	check(floori(72.0*3600.0/32.0)==8100,"72h theoretical score wraps")
	music.queue_free()
	game.queue_free()
	await process_frame
	await process_frame
	print("LONG_RUN_QA checks=",checks," failures=",failures," hours=72 speed=100 ticks=",ticks," sectors=",completed," lamp_episodes=",previous_episodes," indicator_steps=",previous_steps)
	quit(0 if failures==0 else 1)
