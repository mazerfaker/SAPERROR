extends SceneTree
const Store=preload("res://scripts/save/session_store.gd")
var checks: int=0
var failures: int=0
var path: String=""
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)
func _initialize() -> void:
	call_deferred("run")
func raw(target: String,contents: String) -> void:
	var file:=FileAccess.open(target,FileAccess.WRITE)
	if file==null:
		check(false,"fixture write "+target)
		return
	file.store_string(contents)
	file.close()
func value(target: String) -> int:
	return int(Store.load_config(target).get_value("run","sector",-1))
func remove(target: String) -> void:
	if FileAccess.file_exists(target): DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
func run() -> void:
	path="user://qa_save_"+str(OS.get_process_id())+".cfg"
	for suffix in ["",".bak",".tmp",".bak.tmp"]: remove(path+suffix)
	check(Store.load_report(path)["source"]=="new","empty install")
	var cfg:=ConfigFile.new()
	cfg.set_value("meta","version",Store.VERSION)
	cfg.set_value("run","sector",1)
	check(cfg.save(path)==OK and value(path)==1,"legacy v1 readable")
	check(not Store.load_report(path)["sealed"],"legacy migration")
	cfg.set_value("run","sector",2)
	cfg.set_value("stats","archives",["MEMORY_02"])
	check(Store.write_config(cfg,path)==OK,"sealed save")
	check(value(path)==2 and Store.load_report(path)["sealed"],"sealed primary")
	check(value(path+".bak")==1,"legacy backup")
	for sector in range(3,43):
		cfg.set_value("run","sector",sector)
		check(Store.write_config(cfg,path)==OK,"rotation "+str(sector))
		check(value(path)==sector and value(path+".bak")==sector-1,"two valid generations")
		check(not FileAccess.file_exists(path+".tmp"),"staging consumed")
	var original: String=FileAccess.get_file_as_string(path)
	raw(path,original.replace("sector=42","sector=99"))
	check(Store.load_report(path)["source"]=="backup" and value(path)==41,"valid syntax tamper falls back")
	cfg.set_value("run","sector",43)
	check(Store.write_config(cfg,path)==OK,"repair corrupt primary")
	check(value(path)==43 and value(path+".bak")==41,"corrupt primary does not overwrite backup")
	# Interrupted write with intact primary; staged generation is not committed.
	check(DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".tmp"))==OK,"stage fixture")
	check(Store.load_report(path)["source"]=="primary","committed primary wins")
	remove(path)
	check(Store.load_report(path)["source"]=="backup" and value(path)==41,"missing primary recovery")
	remove(path+".bak")
	check(Store.load_report(path)["source"]=="staged" and value(path)==43,"recover only staged copy")
	cfg.set_value("run","sector",44)
	check(Store.write_config(cfg,path)==OK and value(path)==44 and value(path+".bak")==43,"preserve staged-only prior generation")
	# Forced failure before any rotation: .tmp is a directory.
	var stage_abs: String=ProjectSettings.globalize_path(path+".tmp")
	check(DirAccess.make_dir_absolute(stage_abs)==OK,"write failure fixture")
	cfg.set_value("run","sector",45)
	check(Store.write_config(cfg,path)!=OK and value(path)==44 and value(path+".bak")==43,"failed stage preserves saves")
	DirAccess.remove_absolute(stage_abs)
	raw(path,"; SAPERROR-SHA256 invalid\n[meta]\nversion=1")
	raw(path+".bak","; SAPERROR-SHA256 invalid\n[meta]\nversion=1")
	check(Store.load_report(path)["source"]=="invalid","both invalid explicit")
	for suffix in ["",".bak",".tmp",".bak.tmp"]: remove(path+suffix)
	print("SAVE_RECOVERY_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
