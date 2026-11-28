extends SceneTree
const Clock = preload("res://scripts/environment/environment_clock.gd")
const Env = preload("res://scripts/environment/live_environment.gd")
const Geometry = preload("res://scripts/ui/crt_geometry.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	# Fixture sampled from the original animation.js with identical Park-Miller random function.
	var clock := Clock.new()
	clock.start(12345)
	var samples := [[0,3,3,28339.946273872603],[1000,3,3,28339.946273872603],[5000,4,4,28339.946273872603],[20000,5,5,28339.946273872603],[25000,3,6,28339.946273872603],[30000,4,4,50080.0942024589],[50000,5,4,50080.0942024589],[100000,3,4,123911.84800486632],[1000000,5,6,1003970.0307296448],[86400000,2,2,86408640.87324998]]
	for sample in samples:
		clock.tick(float(sample[0]))
		check(clock.level==sample[1] and clock.target==sample[2] and absf(clock.next_episode-float(sample[3]))<0.01,"HTML fixture "+str(sample[0]))
	for i in range(Clock.CUE_TIMES.size()):
		var cue: float = float(Clock.CUE_TIMES[i])
		check(Clock.lamp_at(cue)==Clock.CUE_ON[i],"exact lamp cue")
		check(Clock.lamp_at(cue-0.001)==(true if i==0 else Clock.CUE_ON[i-1]),"before lamp cue")
	check(Clock.lamp_at(500.0),"lamp returns on")
	clock.start(4321)
	var prior_episode: float = clock.next_episode
	var previous_level: int = clock.level
	var count: int = 0
	while clock.next_step<=86400000.0:
		var at: float = clock.next_step
		clock.tick(at)
		check(abs(clock.level-previous_level)==1 and clock.level>=0 and clock.level<=6,"adjacent step")
		var spacing: float = clock.next_step-at
		check(spacing>= (800.0 if clock.level==clock.target else 120.0)-0.001 and spacing<=(3000.0 if clock.level==clock.target else 300.0)+0.001,"approved step/hold range")
		if clock.next_episode!=prior_episode:
			var interval: float = clock.next_episode-prior_episode
			check(interval>=20000.0 and interval<=30000.0,"lamp interval")
			prior_episode=clock.next_episode
			count+=1
		previous_level=clock.level
	check(count>2800 and count<4400,"24-hour lamp episodes")
	var env := Env.new()
	var ready: bool = env.setup(54321)
	var expected: bool = FileAccess.file_exists(Env.ROOT+"config.json")
	check(ready==expected,"asset setup completeness")
	if ready:
		env.automatic = false
		root.add_child(env)
		var initial_nodes: int = env.get_child_count()
		var initial_tex: Dictionary = env.textures.duplicate()
		var initial_player: int = env.player.get_instance_id()
		for _i in range(51840):
			env.advance_virtual(100.0/60.0)
		check(absf(env.clock.time_ms-86400000.0)<0.1,"100x 24h virtual time")
		check(env.clock.serial>=2880 and env.clock.serial<=4320 and env.clock.steps>0,"100x continued animation")
		check(env.get_child_count()==initial_nodes and initial_nodes==1 and env.player.get_instance_id()==initial_player,"fixed audio player")
		check(env.textures==initial_tex and env.textures.size()==21 and env.high_frames.size()==7,"same preloaded textures")
		check(Env.PAPER_PATCH.get_size()==Vector2(112,68),"local paper retouch native dimensions")
		var paper_rect:=Rect2(Env.PAPER_POSITION,Env.PAPER_PATCH.get_size())
		check(Rect2(Vector2.ZERO,Env.NATIVE).encloses(paper_rect),"paper retouch inside original canvas")
		for key in env.layers:
			if key=="base": continue
			var layer: Dictionary=env.layers[key]
			check(not paper_rect.intersects(Rect2(layer["x"],layer["y"],layer["width"],layer["height"])),"paper retouch clear of animated layer "+str(key))
		check(not paper_rect.intersects(Rect2(env.post_position,env.high_frames[0].get_size())),"paper retouch clear of device frames")
		check(env.drawn_level==env.clock.level and env.drawn_lamp==env.clock.lamp_on(),"final frame state")
		env.set_audio_settings(1.0,true)
		check(absf(env.player.volume_db+20.0)<0.001,"nominal -20 dB")
		env.set_audio_settings(0.5,true)
		check(absf(env.player.volume_db-linear_to_db(0.05))<0.001,"game SFX gain")
		env.set_audio_settings(1.0,false)
		check(env.player.volume_db<=-80.0,"game mute")
		env.queue_free()
	else:
		clock.start(54321)
		for i in range(51840): clock.tick(float(i+1)*100000.0/60.0)
		check(absf(clock.time_ms-86400000.0)<0.1,"100x scheduler-only 24h")
		env.free()
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	check((game.live!=null)==ready,"game selects native environment or fallback")
	check((game.frame!=null)!=ready,"no duplicate static background")
	check(game.display.position==Geometry.SCREEN.position and game.display.size==Geometry.SCREEN.size,"CRT alignment")
	check(Geometry.SCREEN.position.distance_to(Geometry.LEGACY_SCREEN.position*Geometry.ART_SCALE)<1.0 and Geometry.SCREEN.end.distance_to(Geometry.LEGACY_SCREEN.end*Geometry.ART_SCALE)<1.0,"pixel-aligned endpoints remain within one source pixel")
	check(game.display.get_index()>(game.live.get_index() if ready else game.frame.get_index()),"CRT above environment")
	check(game.ui!=null and game.raster.size==Geometry.RASTER,"preserve interactive raster")
	game.queue_free()
	print("LIVE_QA checks=",checks," failures=",failures," assets=",ready," stress_hours=24 speed=100")
	quit(0 if failures==0 else 1)
