extends SceneTree
const UI=preload("res://scripts/ui/terminal_ui.gd")
const ActPlate=preload("res://scripts/ui/act_plate.gd")
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
	for locale in ["en","uk"]:
		TranslationServer.set_locale(locale)
		for act in range(4):
			ui.sector_number=[1,4,7,10][act]
			var before: Dictionary=ui.campaign.snapshot()
			ui._show("campaign_intro")
			var plate:=ui.page.find_child("ActIllustration",true,false) as ActPlate
			var dialogue:=ui.page.find_child("ActDialogue",true,false) as Label
			check(is_instance_valid(plate) and is_instance_valid(dialogue),"intro nodes "+locale+" "+str(act))
			if not is_instance_valid(plate) or not is_instance_valid(dialogue): continue
			check(plate.act_index==act and plate.ART[act].get_size()==Vector2(480,380),"imported plate")
			check(not plate.is_processing() and plate.mouse_filter==Control.MOUSE_FILTER_IGNORE,"static accessible art")
			check(dialogue.text==TranslationServer.translate("CAM_ACT_%d" % act) and not dialogue.text.begins_with("CAM_ACT_"),"localized live text")
			check(dialogue.position.x+dialogue.size.x<=plate.position.x and plate.position.y+plate.size.y<810,"separate art and controls")
			check(ui.campaign.snapshot()==before,"view does not change story")
			await process_frame
	ui.queue_free()
	var animated:=ActPlate.new()
	animated.size=Vector2(470,372)
	root.add_child(animated)
	check(animated.is_processing(),"optional fade enabled")
	animated._process(1.0)
	check(animated.reveal==1.0 and not animated.is_processing(),"fade ends without recurring animation")
	animated.queue_free()
	print("ACT_ART_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
