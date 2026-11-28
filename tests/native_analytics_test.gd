extends SceneTree
# Native game scene, real monotonic elapsed time, no production requests.
const Scene=preload("res://scenes/game/gameplay.tscn")
var failures: int=0
var checks: int=0
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("NATIVE_ANALYTICS FAIL: ",msg)
func _initialize() -> void:
	create_timer(75.0).timeout.connect(func(): printerr("NATIVE_ANALYTICS timeout"); quit(1))
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var game=Scene.instantiate()
	game.skip_first_launch_warning=true
	root.add_child(game)
	game._finish_boot()
	var ui=game.ui
	var client=ui.telemetry
	client.set_permission(false)
	# Remove HTTP transport before enabling simulated consent. Never contact production.
	if is_instance_valid(client.request):
		client.request.free()
	client.request=null
	client.configure("https://saperror.example.test")
	client.set_permission(true)
	ui._show("classic")
	root.grab_focus()
	await create_timer(1.5).timeout
	check(root.has_focus(),"actual native window has focus")
	check(ui.screen=="classic","actual classic screen")
	var start: int=Time.get_ticks_msec()
	var before: float=client.active_seconds
	await create_timer(20.0).timeout
	var elapsed: float=float(Time.get_ticks_msec()-start)/1000.0
	var measured: float=client.active_seconds-before
	check(measured>=elapsed-1.5 and measured<=elapsed+1.5,"native active time matches monotonic elapsed seconds")
	check(client.snapshot().get("mode")=="classic","mode captured through actual UI")
	ui._show("menu")
	await process_frame
	var paused: float=client.active_seconds
	await create_timer(2.0).timeout
	check(absf(client.active_seconds-paused)<0.1,"menu time excluded")
	ui._show("classic")
	await create_timer(2.0).timeout
	check(client.active_seconds>paused+1.0,"offline gameplay clock resumes")
	client.set_permission(false)
	check(client.snapshot().is_empty() and client.network_attempts==0,"revocation and zero actual network attempts")
	print("NATIVE_ANALYTICS_QA checks=",checks," failures=",failures," measured_seconds=",measured," elapsed_seconds=",elapsed)
	game.queue_free()
	quit(0 if failures==0 else 1)
