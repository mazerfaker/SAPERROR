extends SceneTree
const Challenge = preload("res://scripts/board/anomaly_challenge.gd")
const Board = preload("res://scripts/board/state.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const ChallengeUI = preload("res://scripts/ui/anomaly_challenge_ui.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, msg: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",msg)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model := Challenge.new()
	check(model.start("LOOP"),"authored LOOP certificate")
	if model.valid:
		var b: Board=model.board()
		var hp: int=b.hp
		for i in range(3): model.act(0,true)
		check(model.loop_done and model.actions==3 and b.cells[0]==model.checkpoint[0] and b.cells[1]==model.checkpoint[1],"local flag reset on third move")
		check(b.hp==hp and b._mask==model.make_mask(Challenge.MASK_A),"no health or mine reset")
		model.act(0,true)
		check(b.cells[0]==Board.Cell.FLAG,"one-shot reset")
		check(model.start("LOOP") and not model.loop_done and model.actions==0,"clean retry")
	check(model.start("DOUBLE"),"two certified authored boards")
	if model.valid:
		check(model.boards.size()==2 and model.certificates.size()==2,"independent certificates")
		var a: Board=model.board()
		var before: PackedInt32Array=a.cells.duplicate()
		model.switch_layer()
		check(model.active_layer==1 and model.board()!=a,"layer switch")
		check(model.marker(13)=="PARALLEL" and model.badge(13)=="A" and model.details().contains(TranslationServer.translate("CH_FIELD_NUMBER") % 2),"explicit links")
		model.act(0,true)
		check(a.cells==before,"other layer unchanged")
		model.switch_layer()
		check(model.active_layer==0 and model.board()==a,"return to layer A")
	check(model.start("WATCHER"),"WATCHER certificate")
	if model.valid:
		check(model.watcher_groups.size()==3 and model.watcher_log.size()==6,"three marked groups")
		var target: int=int(model.watcher_groups[0][0])
		var recorded: int=model.watcher_log[target]
		for i in range(5): model.act(0,true)
		check(model.watcher_closed and model.hidden(target),"groups close after five moves")
		model.toggle_journal()
		check(model.journal_open and model.watcher_log[target]==recorded and model.details().contains("%s: %d" % [model.badge(target),recorded]),"truth preserved in journal")
		check(model.board().clue(target,0)==recorded,"no false ordinary clue")
	check(model.start("LIAR"),"LIAR certificate")
	if model.valid:
		var decoded: Array[int]=model.decoded_sensors()
		var wrong: int=0
		for i in range(3):
			var truth: int=0
			for column in range(Challenge.SIZE): truth+=int(model.board()._mask[int(Challenge.LIAR_ROWS[i])*Challenge.SIZE+column])
			check(decoded[i]==truth,"checksum resolves true row count")
			if model.sensor_values[i]!=decoded[i]: wrong+=1
		check(wrong==1,"exactly one false special sensor")
		check(not model.submit_sensor(0) and not model.liar_solved,"wrong sensor rejected")
		check(model.submit_sensor(1) and model.liar_solved,"correct sensor decoded")
		check(not model.won(),"sensor alone is not victory")
	check(model.start("MAGNET"),"both MAGNET states certified")
	if model.valid:
		var prior: PackedInt32Array=model.board().cells.duplicate()
		var original: PackedByteArray=model.board()._mask.duplicate()
		check(not model.act(0,true),"moves blocked until acknowledged exchange")
		check(model.commit_magnet(),"explicit exchange")
		check(model.board().cells==prior and model.board()._mask==model.make_mask(Challenge.MAGNET_MASK),"only announced mine exchange, open state preserved")
		var changed: Array[int]=[]
		for i in range(original.size()):
			if original[i]!=model.board()._mask[i]: changed.append(i)
		check(changed==[Challenge.MAGNET_SWAP.x,Challenge.MAGNET_SWAP.y],"only marked endpoints changed")
		check(model.certificates.size()==2,"both independent certificates retained")
		check(not model.commit_magnet(),"no second exchange")
	check(model.start("MIMIC"),"MIMIC setup")
	if model.valid:
		var obs: Dictionary=model.board().observation([0])
		check(model.marker(0)=="MIMIC" and model.board().observation([0])==obs,"purely cosmetic closed cell")
	check(model.start("NULL"),"NULL setup")
	if model.valid:
		var proof: Dictionary=Tools.safe_hint(model.board().observation([0]))
		check(not proof.is_empty(),"public proof exists")
		if not proof.is_empty():
			check(int(proof["cell"]) in Challenge.NULL_ZONE and not model.optional_scan() and not model.scan_used,"NULL blocks optional scan without consuming it")
	check(model.start("INSTABILITY"),"INSTABILITY setup")
	if model.valid:
		for i in range(3): model.act(0,true)
		check(model.instability_triggered and model.board().rule==Rules.Rule.CROSS,"announced third action switch")
		model.switch_layer()
		check(model.board().rule==Rules.Rule.CLASSIC,"free return to certified topology")
	# Replay public safe deductions through the actual challenge action path.
	# No mine mask used to select moves. Every authored puzzle must remain finishable.
	for kind in Challenge.KINDS+Challenge.EXTRA_KINDS:
		check(model.start(kind),"full route setup "+kind)
		if not model.valid: continue
		if kind=="WATCHER": model.toggle_journal()
		if kind=="ADMIN_LINK" or kind=="MAGNET": model.switch_layer()
		if kind=="LIAR":
			var truth: Array[int]=model.decoded_sensors()
			for i in range(3):
				if truth[i]!=model.sensor_values[i]: model.submit_sensor(i)
		for step in range(120):
			if model.done(): break
			if model.board().won() and kind=="DOUBLE": model.switch_layer()
			if kind=="INSTABILITY" and model.board().rule!=Rules.Rule.CLASSIC: model.switch_layer()
			var proof: Dictionary=Tools.safe_hint(model.board().observation([0]))
			if proof.is_empty(): break
			if not model.act(int(proof["cell"])): break
		check(model.won() and not model.lost(),"public deductions complete "+kind)
		for board in model.boards: check(board.hp==3,"no damage during certified route")
		var view := ChallengeUI.new()
		view.kind=kind
		view.size=Vector2(1266,710)
		root.add_child(view)
		check(view.model.valid and view.tiles.size()==25,"real UI builds "+kind)
		if view.model.valid:
			for i in range(view.tiles.size()):
				var badge:=view.tiles[i].get_node("MechanicBadge") as Label
				check(badge.text==view.model.badge(i),"visible marker "+kind)
			if kind=="ADMIN_LINK":
				check(view.model.badge(0)=="P" and view.model.badge(24)=="P","portal endpoints")
				check(view.layer_button.text==TranslationServer.translate("PORTAL_DISABLE"),"portal action label")
				view._switch_layer()
				check(view.layer_button.text==TranslationServer.translate("PORTAL_ENABLE"),"portal reverse action")
			if kind=="DOUBLE":
				view._switch_layer()
				check(view.model.active_layer==1,"real layer switch")
			if kind=="WATCHER":
				view._journal()
				check(view.model.journal_open,"real journal switch")
			if kind=="LIAR":
				view._select_sensor(1)
				check(view.model.liar_solved,"real sensor selection")
			view.restart()
			check(view.model.actions==0 and view.tiles.size()==25,"retry reconstructs UI")
		view.queue_free()
	print("CHALLENGE_QA checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
