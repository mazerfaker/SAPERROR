extends SceneTree
const Protocol = preload("res://scripts/ui/protocol_k30.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
const Board = preload("res://scripts/board/state.gd")
const Store = preload("res://scripts/save/session_store.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)
func _initialize() -> void:
	create_timer(90.0).timeout.connect(func(): quit(1))
	call_deferred("run")
func event_for(physical: int, logical: int, down: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.keycode = logical
	event.pressed = down
	event.echo = echo
	return event
func tap(code: Protocol, physical: int, logical: int) -> bool:
	var hit: bool = code.feed(event_for(physical,logical))
	code.feed(event_for(physical,logical,false))
	return hit
func send_window_code(layout_uk: bool = false) -> void:
	for key in Protocol.SEQUENCE:
		var logical: int = key
		if layout_uk and key==KEY_B: logical = 0x418
		if layout_uk and key==KEY_A: logical = 0x424
		root.push_input(event_for(key,logical),true)
		root.push_input(event_for(key,logical,false),true)
func run() -> void:
	var code := Protocol.new()
	for i in range(Protocol.SEQUENCE.size()):
		var key: int = Protocol.SEQUENCE[i]
		check(tap(code,key,key)==(i==9),"correct physical sequence")
	for i in range(Protocol.SEQUENCE.size()):
		var key: int = Protocol.SEQUENCE[i]
		check(tap(code,key,0x410 if key==KEY_A else (0x418 if key==KEY_B else key))==(i==9),"logical layout independent")
	for key in [KEY_UP,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_B,KEY_A]:
		check(not tap(code,key,key),"wrong sequence")
	code.reset_input()
	check(not code.feed(event_for(KEY_UP,KEY_UP)),"first press")
	check(not code.feed(event_for(KEY_UP,KEY_UP,true,true)) and code.prefix.size()==1,"echo ignored")
	check(not code.feed(event_for(KEY_UP,KEY_UP)) and code.prefix.size()==1,"held key ignored")
	code.feed(event_for(KEY_UP,KEY_UP,false))
	for p in range(4):
		var w: int = Profiles.SIZES[p]
		var gen: Dictionary = Profiles.generate(p,1701,0)
		check(not gen.is_empty(),"profile generated")
		if gen.is_empty(): continue
		var board := Board.new(w,w,gen["mask"],Profiles.HP[p])
		board.reveal(0)
		if board.finished(): continue
		var hp: int = board.hp
		var hits: int = board.hits
		var false_flag: int = -1
		for i in range(board.cells.size()):
			if board._mask[i]==0 and board.cells[i]==Board.Cell.CLOSED:
				false_flag = i
				break
		if false_flag >= 0: board.flag(false_flag)
		check(code.prepare(board),"protocol prepares active board")
		var before: int = board.opened
		code.advance(board,1)
		check(board.opened<=before+1,"one tile per step")
		for _i in range(w*w): code.advance(board)
		check(code.done() and board.won(),"protocol completes profile")
		check(board.hp==hp and board.hits==hits,"no damage")
		for i in range(board.cells.size()):
			check(board.cells[i]==(Board.Cell.FLAG if board._mask[i]==1 else Board.Cell.OPEN),"correct final cell")
		check(not code.prepare(board),"finished board cannot repeat")
	var scene: PackedScene = load("res://scenes/game/gameplay.tscn") as PackedScene
	check(scene!=null,"scene loads")
	if scene != null:
		var game = scene.instantiate()
		root.add_child(game)
		var ui = game.ui
		send_window_code()
		check(not ui.protocol_active and ui.protocol.prefix.is_empty(),"window input in menu does not activate")
		ui._start_profile(1)
		ui._reveal(0)
		check(ui.board!=null and not ui.board.finished(),"active UI field")
		if ui.board!=null and not ui.board.finished():
			var before_wins: int = ui.wins
			# No CRT focus: route through the actual root Window, not protocol_input().
			var alternate := Button.new()
			alternate.text = "QA focus sink"
			root.add_child(alternate)
			alternate.grab_focus()
			root.push_input(event_for(KEY_UP,KEY_UP),true)
			root.push_input(event_for(KEY_UP,KEY_UP,true,true),true)
			check(ui.protocol.prefix.size()==1,"window echo counted only once")
			root.push_input(event_for(KEY_UP,KEY_UP,false),true)
			ui.protocol.reset_input()
			send_window_code(true)
			check(ui.protocol_active,"window activation with alternate focus and Ukrainian logical keys")
			alternate.queue_free()
			var old_hp: int = ui.board.hp
			ui._reveal(1)
			check(ui.board.hp==old_hp,"manual input blocked")
			ui._process(4.0)
			check(ui.protocol_finished and ui.pending_sector and ui.wins==before_wins+1,"shared victory accounting")
			ui._process(2.0)
			check(not ui.protocol_active and ui.sector_number==2 and ui.board==null and ui.sector_ready,"next sector transition")
			ui._reveal(0)
			check(ui.board!=null,"next field generation")
			if ui.board!=null and not ui.board.finished():
				var snapshot: Dictionary = Store.snapshot(ui.board,ui.profile,ui.active_seed,ui.first_cell)
				check(not Store.restore(snapshot).is_empty(),"next field resume")
				game.display.grab_focus()
				send_window_code()
				check(ui.protocol_active,"repeat next sector through window with CRT focus")
				ui._process(4.0)
				ui._process(2.0)
				check(ui.sector_number==3 and ui.wins==before_wins+2,"one win per activation")
		game.queue_free()
	print("PROTOCOL_QA checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
