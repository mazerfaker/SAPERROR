extends SceneTree
const BossEmblem = preload("res://scripts/ui/boss_emblem.gd")
const ChallengeUI = preload("res://scripts/ui/anomaly_challenge_ui.gd")
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
	for id in ["WATCHER","LIAR","LOOP","ADMIN"]:
		var art: Texture2D=BossEmblem.ART[id]
		check(art!=null and art.get_size()==Vector2(320,256),"real imported SVG "+id)
		var emblem:=BossEmblem.new()
		emblem.boss_id=id
		emblem.reduced_motion=true
		emblem.size=Vector2(196,154)
		root.add_child(emblem)
		check(not emblem.is_processing() and emblem.mouse_filter==Control.MOUSE_FILTER_IGNORE,"static accessible art "+id)
		emblem.queue_free()
	for kind in ["LOOP","LOOP_B","WATCHER","LIAR","ADMIN_LINK","DOUBLE"]:
		var view:=ChallengeUI.new()
		view.kind=kind
		view.reduced_motion=true
		if kind in ["ADMIN_LINK","DOUBLE"]: view.boss_identity="ADMIN"
		view.size=Vector2(1266,710)
		root.add_child(view)
		check(view.model.valid and view.tiles.size()==25,"unchanged board "+kind)
		check(is_instance_valid(view.emblem),"boss art visible "+kind)
		if is_instance_valid(view.emblem):
			check(view.emblem.position.x>=1060 and view.emblem.position.y+view.emblem.size.y<=164,"header only "+kind)
			check(view.emblem.mouse_filter==Control.MOUSE_FILTER_IGNORE,"no input interception "+kind)
		view.restart()
		check(is_instance_valid(view.emblem) and view.tiles.size()==25,"retry preserves layout "+kind)
		view.queue_free()
	print("BOSS_ART_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
