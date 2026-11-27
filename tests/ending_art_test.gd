extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const EndingPlate=preload("res://scripts/ui/ending_plate.gd")
const Campaign=preload("res://scripts/run/campaign.gd")
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
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui._start_profile(1,true)
	ui.reduced=true
	ui.ending_gallery.assign(Campaign.ENDINGS)
	for locale in ["en","uk"]:
		TranslationServer.set_locale(locale)
		for id in Campaign.ENDINGS:
			var before: Dictionary=ui.campaign.snapshot()
			var gallery: Array[String]=ui.ending_gallery.duplicate()
			ui._show_gallery_ending(id)
			var plate:=ui.page.find_child("EndingIllustration",true,false) as EndingPlate
			var dialogue:=ui.page.find_child("EndingDialogue",true,false) as Label
			check(is_instance_valid(plate) and is_instance_valid(dialogue),"gallery scene "+locale+" "+id)
			if not is_instance_valid(plate) or not is_instance_valid(dialogue): continue
			check(plate.ending_id==id and EndingPlate.ART[id].get_size()==Vector2(480,380),"imported art")
			check(not plate.is_processing() and plate.mouse_filter==Control.MOUSE_FILTER_IGNORE,"static decoration")
			check(dialogue.text==TranslationServer.translate("CAM_END_"+id) and not dialogue.text.begins_with("CAM_END_"),"localized story")
			check(dialogue.position.x+dialogue.size.x<=plate.position.x and plate.position.y+plate.size.y<810,"art separated from controls")
			check(ui.campaign.snapshot()==before and ui.ending_gallery==gallery,"view cannot change progression")
			var back_button:=ui.page.find_child("EndingBack",true,false) as Button
			check(is_instance_valid(back_button),"back control")
			if is_instance_valid(back_button): back_button.pressed.emit()
			check(ui.screen=="gallery","return to gallery")
			await process_frame
	for id in Campaign.ENDINGS:
		var animated:=EndingPlate.new()
		animated.ending_id=id
		animated.size=Vector2(470,372)
		root.add_child(animated)
		check(animated.is_processing() and animated.progress==0.0,"transition starts")
		animated._process(1.0)
		check(animated.progress==1.0 and not animated.is_processing(),"transition terminates")
		animated.queue_free()
	ui.queue_free()
	print("ENDING_ART_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
