extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const Store=preload("res://scripts/save/session_store.gd")
const Env=preload("res://scripts/environment/live_environment.gd")
var checks: int=0
var failures: int=0
var path: String
func check(ok: bool,msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func open_ui() -> UI:
	var ui:=UI.new()
	ui.require_content_warning=true
	ui.session_path=path
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	return ui
func clean() -> void:
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
func run() -> void:
	path="user://qa_rc_"+str(OS.get_process_id())+".cfg"
	clean()
	var ui:=open_ui()
	check(ui.warning_pending and ui.screen=="warning" and not ui.audio.enabled,"warning precedes sound and menu")
	ui._show("game")
	check(ui.screen=="warning" and not ui.back_shortcut(),"cannot bypass first warning")
	ui._save_session()
	check(not FileAccess.file_exists(path),"no premature acknowledgement save")
	var safe:=ui.page.find_child("WarningSafe",true,false) as Button
	check(is_instance_valid(safe),"real reduced effects control")
	if is_instance_valid(safe): safe.pressed.emit()
	check(ui.screen=="menu" and ui.warning_acknowledged and ui.clear_display and ui.reduced and not ui.lamp_animation and not ui.audio.enabled,"reduced effects preset")
	ui.queue_free()
	await process_frame
	ui=open_ui()
	check(not ui.warning_pending and ui.screen=="menu" and ui.warning_acknowledged,"acknowledgement persists")
	check(not ui.lamp_animation and ui.clear_display and not ui.audio.enabled,"quiet preferences persist")
	ui._show("accessibility")
	var lamp:=ui.page.find_child("LampSetting",true,false) as Button
	check(is_instance_valid(lamp),"independent lamp switch")
	if is_instance_valid(lamp): lamp.pressed.emit()
	check(ui.lamp_animation and ui.clear_display,"lamp independent of CRT")
	ui.queue_free()
	await process_frame
	clean()
	ui=open_ui()
	var normal:=ui.page.find_child("WarningContinue",true,false) as Button
	check(is_instance_valid(normal),"normal consent control")
	if is_instance_valid(normal): normal.pressed.emit()
	check(ui.audio.enabled and ui.lamp_animation and not ui.clear_display and not ui.warning_pending,"normal defaults preserved")
	ui.queue_free()
	await process_frame
	clean()
	var env:=Env.new()
	check(env.setup(54321),"exact live assets")
	if env.ready_assets:
		env.automatic=false
		root.add_child(env)
		env.set_lamp_enabled(false)
		for _i in range(1800):
			env.advance_virtual(0.1)
			check(env.drawn_lamp,"no lamp flashes while disabled")
		check(env.clock.steps>0 and env.clock.serial>0,"indicator and clock continue")
		env.set_lamp_enabled(true)
		var dark: bool=false
		for _i in range(800):
			env.advance_virtual(0.05)
			if not env.drawn_lamp: dark=true
		check(dark,"approved lamp animation resumes")
		env.queue_free()
	else: env.free()
	for lang in ["uk","en"]:
		TranslationServer.set_locale(lang)
		for id in ["RC_WARNING_TITLE","RC_WARNING_TEXT","RC_WARNING_CONTINUE","RC_WARNING_SAFE","RC_LAMP"]:
			check(TranslationServer.translate(id)!=id,"localized "+lang+" "+id)
	print("RC_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
