extends SceneTree
const Collection=preload("res://scripts/run/collection.gd")
const UI=preload("res://scripts/ui/terminal_ui.gd")
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
	var cfg:=ConfigFile.new()
	cfg.set_value("stats","archives",["MEMORY_02","UNKNOWN","MEMORY_02",17])
	cfg.set_value("stats","lab_completed",["LOOP","LOOP","ADMIN_LINK"])
	var c:=Collection.new()
	var prior: Array[String]=["MEMORY_05"]
	c.restore(cfg,prior)
	check(c.archives==["MEMORY_02","MEMORY_05"] and c.trials==["LOOP"],"sanitize and migrate")
	check(not c.recover("MEMORY_02") and not c.recover("BAD"),"duplicates and invalid rejected")
	check(c.recover("MEMORY_08") and c.finish_trial("LIAR"),"new entries")
	c.write(cfg)
	var copy:=Collection.new()
	var empty: Array[String]=[]
	copy.restore(cfg,empty)
	check(copy.archives==c.archives and copy.trials==c.trials,"collection config round trip")
	var ui:=UI.new()
	ui.size=Vector2(1426,962)
	root.add_child(ui)
	ui.collection=copy
	ui._start_profile(1,true)
	check(ui.collection.archives.size()==3 and ui.campaign.records.is_empty(),"new campaign preserves collection but not keys")
	ui.ending_gallery.assign(["SHUTDOWN"])
	ui._show("gallery")
	var locked:=ui.page.find_child("EndingCard_REWRITE",true,false) as Button
	check(is_instance_valid(locked) and locked.disabled,"locked endings stay hidden")
	ui._show("archives")
	var credits: int=ui.economy.credits
	for locale in ["en","uk"]:
		TranslationServer.set_locale(locale)
		for id in Collection.RECORDS:
			ui._open_archive(id)
			var record:=ui.page.find_child("ArchiveText",true,false) as Label
			check(is_instance_valid(record) and record.text==TranslationServer.translate("COL_BODY_"+id) and not record.text.begins_with("COL_BODY_"),"localized record "+id)
			check(ui.economy.credits==credits and ui.campaign.records.is_empty(),"read only archive")
			await process_frame
	ui._show("challenges")
	var lab:=ui.page.find_child("LabCard_LOOP",true,false) as Button
	check(is_instance_valid(lab) and lab.text.contains("✓"),"completed trial marker")
	ui.queue_free()
	print("COLLECTION_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
