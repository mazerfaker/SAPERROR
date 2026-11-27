extends SceneTree
const Scene=preload("res://scenes/game/gameplay.tscn")
const Board=preload("res://scripts/board/state.gd")
const Classic=preload("res://scripts/board/classic_game.gd")
const ClassicUI=preload("res://scripts/ui/classic_ui.gd")
const ChallengeUI=preload("res://scripts/ui/anomaly_challenge_ui.gd")
const StyleBank=preload("res://scripts/ui/style_bank.gd")
const PerformanceReadout=preload("res://scripts/ui/performance_panel.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var bank:=StyleBank.new()
	var style:=bank.get_style(Color.RED,Color.GREEN,3)
	for i in range(200): check(bank.get_style(Color.RED,Color.GREEN,3)==style,"shared immutable style")
	check(bank.allocations==1,"one allocation for 201 requests")
	for i in range(160): bank.get_style(Color(float(i)/160.0,0,0),Color.GREEN)
	check(bank.entries.size()<=StyleBank.LIMIT,"bounded cache")
	var game=Scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	var ui=game.ui
	game._set_effects(0.45,true,false,false,0.0,false)
	check(not game.grade_layer.visible,"zero strength grade hidden")
	game._set_effects(0.45,true,false,false,0.25,false)
	check(game.grade_layer.visible,"nonzero grade restored")
	game._process(0.016)
	var updates: int=game.crt_parameter_writes
	for i in range(120): game._process(0.016)
	check(game.crt_parameter_writes==updates,"idle CRT writes suppressed")
	game._on_fault()
	game._process(0.016)
	check(game.crt_parameter_writes>updates and float(game.crt_material.get_shader_parameter("fault"))>0.0,"fault effect still updates")
	ui.reduced=true
	ui._start_profile(1)
	ui._reveal(0)
	check(ui.board!=null,"active board")
	if ui.board!=null:
		ui._refresh()
		var allocations: int=ui.style_bank.allocations
		var before: StyleBox=ui.buttons[0].get_theme_stylebox("normal")
		for i in range(120): ui._refresh()
		check(ui.refresh_style_writes==0 and ui.style_bank.allocations==allocations,"idle grid no style writes or allocations")
		check(ui.buttons[0].get_theme_stylebox("normal")==before,"same style object")
		var index: int=ui.board.cells.find(Board.Cell.CLOSED)
		if index>=0:
			ui._flag_action(index)
			check(ui.buttons[index].text=="⚑" and ui.refresh_style_writes>0,"changed flag refreshed")
			ui._flag_action(index)
			check(ui.buttons[index].text=="·","flag removed")
		else: check(false,"closed cell available")
	var env=game.live
	if is_instance_valid(env):
		env.set_audio_settings(0.5,true)
		var writes: int=env.audio_gain_writes
		for i in range(120): env.set_audio_settings(0.5,true)
		check(env.audio_gain_writes==writes,"no repeated mixer writes")
		env.set_audio_settings(0.25,true)
		check(env.audio_gain_writes==writes+1,"changed mixer level")
	else: check(false,"live assets present")
	ui._show("performance")
	var panel:=ui.page.find_child("PerformanceReadout",true,false) as PerformanceReadout
	check(is_instance_valid(panel),"diagnostic panel")
	if is_instance_valid(panel):
		var samples: int=panel.samples
		for i in range(60): panel._process(1.0/60.0)
		check(panel.samples==samples+1 or panel.samples==samples,"bounded sampling")
		panel._process(0.1)
		check(panel.samples>=samples+1,"sample once elapsed")
	game.queue_free()
	var classic:=ClassicUI.new()
	classic.model=Classic.new()
	classic.model.start(1,1701)
	classic.size=Vector2(1266,710)
	root.add_child(classic)
	classic.set_process(false)
	classic._move(0,"reveal")
	var readouts: int=classic.readout_updates
	var allocated: int=classic.style_bank.allocations
	for i in range(59): classic._process(1.0/60.0)
	check(classic.readout_updates==readouts,"no subsecond timer redraw")
	classic._process(0.1)
	check(classic.readout_updates==readouts+1,"second tick")
	classic.refresh()
	check(classic.style_bank.allocations==allocated,"classic style reuse")
	classic.queue_free()
	var trial:=ChallengeUI.new()
	trial.size=Vector2(1266,710)
	root.add_child(trial)
	var trial_alloc: int=trial.style_bank.allocations
	for i in range(120): trial.refresh()
	check(trial.style_bank.allocations==trial_alloc,"lab style reuse")
	trial.queue_free()
	print("PERFORMANCE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
