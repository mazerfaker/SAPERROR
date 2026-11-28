extends RefCounted
# Authored challenge state, independent of campaign HP, economy and saves.
const Board = preload("res://scripts/board/state.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Rules = preload("res://scripts/board/rules.gd")
const Tools = preload("res://scripts/board/onboarding_tools.gd")
const Protocol = preload("res://scripts/ui/protocol_k30.gd")
const SIZE := 5
const FIRST := 12
const MASK_A := [0,1,14,21]
const MASK_B := [0,2,10,19]
const KINDS := ["LOOP","DOUBLE","WATCHER","LIAR","MIMIC","NULL","INSTABILITY","MAGNET"]
const MIMIC_ZONE := [0,2,4,14,20,22,24]
const NULL_ZONE := [0,1,2,3,4,9,14,19,20,21,22,23,24]
const MAGNET_SWAP := Vector2i(1,2)
const MAGNET_MASK := [0,2,14,21]
const EXTRA_KINDS := ["LOOP_B","ADMIN_LINK","REWRITE"]
const LIAR_ROWS := [0,2,4]
const DOUBLE_LINKS := [Vector2i(11,13),Vector2i(13,11)]
var kind: String = "LOOP"
var starting_hp: int=3
var boards: Array[Board] = []
var certificates: Array[Dictionary] = []
var active_layer: int = 0
var actions: int = 0
var valid: bool = false
var loop_done: bool = false
var loop_zone: Array[int] = [0,1,2,3,4,5,6,7,8,9]
var checkpoint: PackedInt32Array
var notice: String = ""
var watcher_groups: Array[PackedInt32Array] = []
var watcher_log: Dictionary = {}
var watcher_closed: bool = false
var journal_open: bool = false
var sensor_values: Array[int] = []
var checksum_values: Array[int] = []
var liar_solved: bool = false
var liar_bad: int = 1
var magnet_committed: bool = false
var instability_triggered: bool = false
var scan_used: bool = false
var scan_cell: int = -1
var reworked: bool=false
var rework_phase: int=0
var corruption: Dictionary={}
var corruption_until: int=0
var reopened: Dictionary={}
var initial_open: PackedInt32Array
var boost: String=""
var shield_used: bool=false
var stabilized: bool=false
var hints_remaining: int=0
func make_mask(mines: Array) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(SIZE*SIZE)
	for i in mines: mask[int(i)]=1
	return mask
func add_board(mines: Array) -> bool:
	var mask: PackedByteArray = make_mask(mines)
	var proof: Dictionary = Validator.certify(SIZE,SIZE,mask,FIRST,[Rules.Rule.CLASSIC])
	if proof.is_empty(): return false
	var b := Board.new(SIZE,SIZE,mask,starting_hp)
	b.reveal(FIRST)
	boards.append(b)
	certificates.append(proof)
	return not b.finished()
func start(next_kind: String, integrity: int=3) -> bool:
	reworked=false
	kind = next_kind
	starting_hp=clampi(integrity,1,5)
	boards.clear()
	certificates.clear()
	active_layer=0
	actions=0
	loop_done=false
	notice=""
	watcher_groups.clear()
	watcher_log.clear()
	watcher_closed=false
	journal_open=false
	sensor_values.clear()
	checksum_values.clear()
	liar_solved=false
	magnet_committed=false
	instability_triggered=false
	scan_used=false
	scan_cell=-1
	valid=false
	loop_zone.assign([15,16,17,18,19,20,21,22,23,24] if kind=="LOOP_B" else [0,1,2,3,4,5,6,7,8,9])
	if kind not in KINDS and kind not in EXTRA_KINDS: return false
	if not add_board(MASK_B if kind in ["LOOP_B","REWRITE"] else MASK_A): return false
	if kind=="ADMIN_LINK": board().configure_portal(0,24)
	if kind=="DOUBLE":
		if not add_board(MASK_B): return false
		for link in DOUBLE_LINKS:
			if boards[0].cells[link.x]!=Board.Cell.OPEN or boards[1].cells[link.y]!=Board.Cell.OPEN: return false
	if kind=="MAGNET":
		var alternate: PackedByteArray=make_mask(MAGNET_MASK)
		var proof: Dictionary=Validator.certify(SIZE,SIZE,alternate,FIRST,[Rules.Rule.CLASSIC])
		if proof.is_empty(): return false
		var preview := Board.new(SIZE,SIZE,alternate,starting_hp)
		preview.reveal(FIRST)
		if preview.cells!=board().cells or preview.finished(): return false
		certificates.append(proof)
	checkpoint=board().cells.duplicate()
	if kind=="WATCHER":
		var open_ids: Array[int] = []
		for i in range(board().cells.size()):
			if board().cells[i]==Board.Cell.OPEN: open_ids.append(i)
		if open_ids.size()<6: return false
		for group in range(3):
			var pair := PackedInt32Array([open_ids[group*2],open_ids[group*2+1]])
			watcher_groups.append(pair)
			for index in pair: watcher_log[index]=board().clue(index,0)
	if kind=="LIAR":
		var truth: Array[int] = []
		for row in LIAR_ROWS:
			var total: int = 0
			for column in range(SIZE): total += int(board()._mask[int(row)*SIZE+column])
			truth.append(total)
		sensor_values=truth.duplicate()
		sensor_values[liar_bad]+=1
		checksum_values.assign([truth[0]+truth[1],truth[1]+truth[2],truth[0]+truth[2]])
	valid=true
	return true
# New story encounters are certified CLASSIC boards, not authored sensor puzzles.
func start_reworked(next_kind: String, integrity: int, profile: int, seed_value: int, reward_id: String) -> bool:
	reworked=true
	kind=next_kind
	starting_hp=clampi(integrity,1,5)
	boards.clear()
	certificates.clear()
	active_layer=0
	actions=0
	valid=false
	notice=""
	rework_phase=0
	corruption.clear()
	corruption_until=0
	reopened.clear()
	loop_done=false
	boost=reward_id
	shield_used=false
	stabilized=false
	hints_remaining=2 if boost=="ASSISTANT" else 0
	scan_cell=-1
	if kind not in ["WATCHER","LIAR","LOOP","ADMIN"]: return false
	var side: int=12 if kind=="ADMIN" else 8
	var density: int=int(([18,22,26,28] if kind=="ADMIN" else [8,10,12,14])[clampi(profile,0,3)])
	var first: int=side*(side/2)+side/2
	var safe: Array[int]=Rules.neighbors(side,side,first,Rules.Rule.CLASSIC)
	safe.append(first)
	var allowed: Array[int]=[]
	for i in range(side*side):
		if not safe.has(i): allowed.append(i)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%s:%d:%d" % [kind,seed_value,profile])
	var rules: Array[int]=[Rules.Rule.CLASSIC]
	for attempt in range(64):
		var pool: Array[int]=allowed.duplicate()
		var mask:=PackedByteArray()
		mask.resize(side*side)
		for j in range(density):
			var k: int=rng.randi_range(j,pool.size()-1)
			var swap: int=pool[j]
			pool[j]=pool[k]
			pool[k]=swap
			mask[pool[j]]=1
		var candidate:=Board.new(side,side,mask,starting_hp)
		candidate.reveal(first)
		if candidate.finished() or candidate.opened>(side*side-density)*0.55: continue
		var proof: Dictionary=Validator.certify(side,side,mask,first,rules)
		if proof.is_empty(): continue
		boards.append(candidate)
		certificates.append(proof)
		initial_open=candidate.cells.duplicate()
		valid=true
		return true
	# Bounded certified fallback: edge bands with an isolated interior mine.
	for offset in range(side):
		var mask:=PackedByteArray()
		mask.resize(side*side)
		var count: int=0
		for step in range(side*side):
			var i: int=posmod(step+offset,side*side)
			if safe.has(i) or i==0 or count>=density-1: continue
			mask[i]=1
			count+=1
		var last: int=side*(side-2)+side-2
		if safe.has(last) or mask[last]!=0 or count!=density-1: continue
		mask[last]=1
		var candidate:=Board.new(side,side,mask,starting_hp)
		candidate.reveal(first)
		if candidate.finished(): continue
		var proof: Dictionary=Validator.certify(side,side,mask,first,rules)
		if proof.is_empty(): continue
		boards.append(candidate)
		certificates.append(proof)
		initial_open=candidate.cells.duplicate()
		valid=true
		return true
	return false
func effect_kind() -> String:
	return ["WATCHER","LIAR","LOOP"][rework_phase] if kind=="ADMIN" else kind
func restore_signal() -> bool:
	if not reworked or corruption.is_empty() or done(): return false
	corruption.clear()
	notice="RC7_SIGNAL_RESTORED"
	return true
func reward_hint() -> bool:
	if not reworked or not valid or done() or hints_remaining<=0: return false
	var proof: Dictionary=Tools.safe_hint(board().observation([Rules.Rule.CLASSIC]))
	if proof.is_empty(): return false
	scan_cell=int(proof["cell"])
	hints_remaining-=1
	notice="CH_SCAN_FOUND"
	return true
func display_clue(index: int) -> String:
	var number: int=board().clue(index,board().rule)
	if reworked and corruption.get(index,"")=="LIAR": return str((number+1)%9)+"!"
	return str(number)
func _rework_act(index: int, flag: bool, chord: bool) -> bool:
	var b: Board=board()
	if chord and corruption.has(index): return false
	var before: PackedInt32Array=b.cells.duplicate()
	var before_hits: int=b.hits
	if flag: b.flag(index)
	elif chord: b.chord(index)
	else: b.reveal(index)
	if before==b.cells: return false
	if b.hits>before_hits and boost=="SECOND_LIFE" and not shield_used:
		shield_used=true
		b.hp+=1
		notice="RC7_SHIELD_USED"
	else: notice=""
	if flag: return true
	actions+=1
	scan_cell=-1
	for cell in reopened.keys():
		if b.cells[cell]==Board.Cell.OPEN: reopened.erase(cell)
	if b.finished():
		corruption.clear()
		return true
	if actions>=corruption_until: corruption.clear()
	if kind=="ADMIN":
		var fraction: float=float(b.opened)/maxi(1,b.cells.size()-b.mine_total)
		var next_phase: int=mini(2,floori(fraction*3.0))
		if next_phase>rework_phase:
			rework_phase=next_phase
			corruption.clear()
			notice="RC7_PHASE_CHANGED"
	var effect: String=effect_kind()
	if actions%4!=0 or (effect=="LOOP" and loop_done): return true
	if boost=="STABILIZER" and not stabilized:
		stabilized=true
		notice="RC7_STABILIZED"
		return true
	if effect=="LOOP":
		for i in range(b.cells.size()-1,-1,-1):
			if reopened.size()>=2: break
			if b.cells[i]==Board.Cell.OPEN and initial_open[i]!=Board.Cell.OPEN:
				b.cells[i]=Board.Cell.CLOSED
				b.opened-=1
				reopened[i]=true
		loop_done=not reopened.is_empty()
		if loop_done: notice="RC7_LOOP_EVENT"
	else:
		corruption.clear()
		# Only already visible clues are affected; the true board and mine map never change.
		for offset in range(b.cells.size()):
			var i: int=posmod(offset+actions*7,b.cells.size())
			if b.cells[i]==Board.Cell.OPEN and b.clue(i,b.rule)>0:
				corruption[i]=effect
				if corruption.size()>=3: break
		corruption_until=actions+2
		if not corruption.is_empty(): notice="RC7_"+effect+"_EVENT"
	return true
func board() -> Board:
	return boards[active_layer]
func won() -> bool:
	if not valid or (not reworked and kind=="LIAR" and not liar_solved): return false
	for b in boards:
		if not b.won(): return false
	return true
func lost() -> bool:
	if not valid: return false
	for b in boards:
		if b.hp<=0: return true
	return false
func done() -> bool:
	return won() or lost()
func act(index: int, flag: bool = false, chord: bool = false) -> bool:
	if not valid or done() or board().finished() or index<0 or index>=board().cells.size(): return false
	if reworked: return _rework_act(index,flag,chord)
	if kind=="MAGNET" and not magnet_committed: return false
	var b: Board = board()
	var before: PackedInt32Array = b.cells.duplicate()
	if flag: b.flag(index)
	elif chord: b.chord(index)
	else: b.reveal(index)
	if b.cells==before: return false
	actions += 1
	notice=""
	scan_cell=-1
	if kind=="INSTABILITY" and not instability_triggered and actions>=3 and not b.finished():
		instability_triggered=true
		b.rule=Rules.Rule.CROSS
		notice="CH_INST_SWITCH"
	if kind in ["LOOP","LOOP_B"] and not loop_done and b.hp>0 and (actions>=3 or b.won()):
		apply_loop()
	if kind=="WATCHER" and not watcher_closed and actions>=5:
		watcher_closed=true
		notice="CH_WATCHER_CLOSED"
	return true
# Secret K-30 override satisfies authored gates without changing normal moves.
func protocol_complete() -> bool:
	if not valid or lost(): return false
	if kind=="MAGNET" and not magnet_committed and not commit_magnet(): return false
	if not reworked and kind=="LIAR" and not liar_solved and not submit_sensor(liar_bad): return false
	if reworked: corruption.clear()
	if kind in ["LOOP","LOOP_B"]: loop_done=true
	var override:=Protocol.new()
	for b in boards:
		if b.won(): continue
		if not override.prepare(b): return false
		override.advance(b,b.cells.size())
		if not b.won(): return false
	notice=""
	scan_cell=-1
	return won()
func apply_loop() -> void:
	var b: Board = board()
	# Rewind the marked local region only once. Neutralized mines and health are never refunded.
	for i in loop_zone:
		if b.cells[i]==Board.Cell.NEUTRALIZED: continue
		if b.cells[i]==Board.Cell.OPEN and checkpoint[i]!=Board.Cell.OPEN: b.opened-=1
		if b.cells[i]!=Board.Cell.OPEN and checkpoint[i]==Board.Cell.OPEN: b.opened+=1
		b.cells[i]=checkpoint[i]
	loop_done=true
	notice="CH_LOOP_RESET"
func switch_layer() -> void:
	if not valid or done(): return
	if kind=="DOUBLE": active_layer=1-active_layer
	elif kind=="ADMIN_LINK": board().portal_enabled=not board().portal_enabled
	elif kind=="INSTABILITY" and instability_triggered:
		board().rule=Rules.Rule.CLASSIC if board().rule==Rules.Rule.CROSS else Rules.Rule.CROSS
	elif kind=="MAGNET": commit_magnet()
func commit_magnet() -> bool:
	# Explicit one-shot exchange before any action. Both endpoint cells are closed.
	if not valid or kind!="MAGNET" or magnet_committed or actions!=0: return false
	var b: Board=board()
	if b.cells[MAGNET_SWAP.x]!=Board.Cell.CLOSED or b.cells[MAGNET_SWAP.y]!=Board.Cell.CLOSED: return false
	var alternate := Board.new(SIZE,SIZE,make_mask(MAGNET_MASK),b.hp)
	alternate.reveal(FIRST)
	if alternate.cells!=b.cells or alternate.mine_total!=b.mine_total: return false
	boards[0]=alternate
	magnet_committed=true
	notice="CH_MAGNET_COMMITTED"
	return true
func optional_scan() -> bool:
	if not valid or kind!="NULL" or done() or scan_used: return false
	var proof: Dictionary=Tools.safe_hint(board().observation([Rules.Rule.CLASSIC]))
	if proof.is_empty():
		notice="CH_SCAN_NONE"
		return false
	var index: int=int(proof["cell"])
	if index in NULL_ZONE:
		notice="CH_NULL_BLOCKED"
		return false
	scan_used=true
	scan_cell=index
	notice="CH_SCAN_FOUND"
	return true
func decoded_sensors() -> Array[int]:
	if checksum_values.size()!=3: return []
	var a: int = (checksum_values[0]+checksum_values[2]-checksum_values[1])/2
	return [a,checksum_values[0]-a,checksum_values[2]-a]
func submit_sensor(index: int) -> bool:
	if not valid or kind!="LIAR" or lost() or liar_solved or index<0 or index>=3: return false
	var decoded: Array[int] = decoded_sensors()
	if sensor_values[index]==decoded[index]:
		notice="CH_LIAR_WRONG"
		return false
	liar_solved=true
	notice="CH_LIAR_CORRECT"
	return true
func toggle_journal() -> void:
	if kind=="WATCHER": journal_open=not journal_open
func marker(index: int) -> String:
	if reworked: return str(corruption.get(index,""))
	if kind=="MIMIC" and index in MIMIC_ZONE and board().cells[index]==Board.Cell.CLOSED: return "MIMIC"
	if kind=="NULL" and index in NULL_ZONE: return "NULL"
	if kind=="MAGNET" and index in [MAGNET_SWAP.x,MAGNET_SWAP.y]: return "MAGNET"
	if index==scan_cell: return "SCAN"
	if kind=="LIAR":
		var row: int = index/SIZE
		if LIAR_ROWS.has(row): return "S%d" % (LIAR_ROWS.find(row)+1)
	if kind=="WATCHER":
		for g in range(watcher_groups.size()):
			if watcher_groups[g].has(index): return "WATCHER G%d" % (g+1)
	if kind=="DOUBLE":
		for link in DOUBLE_LINKS:
			if index==(link.x if active_layer==0 else link.y): return "PARALLEL"
	if kind=="ADMIN_LINK" and index in [0,24]: return "PORTAL"
	return "LOOP" if kind in ["LOOP","LOOP_B"] and not loop_done and index in loop_zone else ""
func hidden(index: int) -> bool:
	if reworked: return corruption.get(index,"")=="WATCHER"
	return kind=="WATCHER" and watcher_closed and watcher_log.has(index)
# Visible labels refer to public evidence, not hidden mine data.
func badge(index: int) -> String:
	if reworked:
		if index==scan_cell: return "✓"
		if corruption.has(index): return "!"
		if reopened.has(index): return "↺"
		return ""
	if kind=="ADMIN_LINK" and index in [0,24]: return "P"
	if kind=="MAGNET" and index in [MAGNET_SWAP.x,MAGNET_SWAP.y]: return "M"
	if kind=="WATCHER":
		for g in range(watcher_groups.size()):
			for j in range(watcher_groups[g].size()):
				if watcher_groups[g][j]==index: return "ABCDEF".substr(g*2+j,1)
	if kind=="DOUBLE":
		for j in range(DOUBLE_LINKS.size()):
			var link: Vector2i=DOUBLE_LINKS[j]
			if index==(link.x if active_layer==0 else link.y): return "AB".substr(j,1)
	if kind=="LIAR":
		var row: int=index/SIZE
		if LIAR_ROWS.has(row): return "ABC".substr(LIAR_ROWS.find(row),1)
	if index==scan_cell: return "✓"
	if not marker(index).is_empty():
		if kind=="NULL": return "N"
		if kind=="MIMIC": return "~"
		if kind in ["LOOP","LOOP_B"]: return "L"
	return ""
func cell_description(index: int) -> String:
	if reworked:
		if corruption.has(index): return tr("RC7_SIGNAL_HELP")
		if reopened.has(index): return tr("RC7_LOOP_SAFE")
		if index==scan_cell: return tr("CH_SCAN_FOUND")
		return ""
	var tag: String=badge(index)
	if kind=="ADMIN_LINK" and tag=="P": return tr("PORTAL_EXPLAIN_ON" if board().portal_enabled else "PORTAL_EXPLAIN_OFF")
	if kind=="MAGNET" and tag=="M": return tr("CH_MAGNET_COMMITTED" if magnet_committed else "CH_MAGNET_WARNING")
	if kind=="WATCHER" and not tag.is_empty():
		return tr("CH_WATCHER_SAVED") % [tag,watcher_log[index]] if journal_open else tr("CH_WATCHER_MARK") % tag
	if kind=="DOUBLE" and not tag.is_empty(): return tr("CH_PAIR_MARK") % tag
	if kind=="LIAR" and not tag.is_empty(): return tr("CH_SENSOR_NAME") % tag
	if index==scan_cell: return tr("CH_SCAN_FOUND")
	if not tag.is_empty():
		if kind=="NULL": return tr("CH_NULL_STATUS")
		if kind=="MIMIC": return tr("CH_MIMIC_STATUS")
		if kind in ["LOOP","LOOP_B"]: return tr("CH_LOOP_COUNT")+" "+str(maxi(0,3-actions))
	return ""
func details() -> String:
	if reworked:
		var prefix: String=tr("RC7_PHASE") % [rework_phase+1,effect_kind()]+"\n" if kind=="ADMIN" else ""
		return prefix+tr("RC7_BOSS_"+effect_kind())
	if kind=="MIMIC": return tr("CH_MIMIC_STATUS")
	if kind=="NULL": return tr("CH_NULL_STATUS")+"\n"+(tr("CH_SCAN_HIGHLIGHT") if scan_cell>=0 else tr("CH_SCAN_SPENT" if scan_used else "CH_SCAN_READY"))
	if kind=="INSTABILITY": return tr("CH_RULE_CLASSIC" if board().rule==Rules.Rule.CLASSIC else "CH_RULE_CROSS")+"\n"+(tr("CH_INST_SWITCH") if instability_triggered else tr("CH_INST_COUNT")+" "+str(maxi(0,3-actions)))
	if kind=="MAGNET": return tr("CH_MAGNET_COMMITTED" if magnet_committed else "CH_MAGNET_WARNING")
	if kind=="LIAR":
		var readings: Array[int] = decoded_sensors() if liar_solved else sensor_values
		return tr("CH_SENSOR_READINGS") % [readings[0],readings[1],readings[2]]+"\n"+tr("CH_SENSOR_SUMS") % [checksum_values[0],checksum_values[1],checksum_values[2]]+"\n"+tr("CH_LIAR_CORRECT" if liar_solved else "CH_LIAR_SELECT")
	if kind=="WATCHER":
		var status: String = tr("CH_WATCHER_CLOSED") if watcher_closed else tr("CH_WATCHER_COUNT")+" "+str(maxi(0,5-actions))
		if not journal_open: return status+"\n"+tr("CH_WATCHER_MARKS")
		var lines := PackedStringArray([status,tr("CH_WATCHER_VALUES")])
		for g in range(watcher_groups.size()):
			var pair := PackedStringArray()
			for index in watcher_groups[g]:
				pair.append("%s: %d" % [badge(index),watcher_log[index]])
			lines.append("   ".join(pair))
		return "\n".join(lines)
	if kind=="DOUBLE":
		var lines := PackedStringArray([tr("CH_FIELD_NUMBER") % (active_layer+1),tr("CH_DOUBLE_LINKS")])
		for j in range(DOUBLE_LINKS.size()):
			var link: Vector2i=DOUBLE_LINKS[j]
			lines.append(tr("CH_PAIR_VALUES") % ["AB".substr(j,1),boards[0].clue(link.x,0),boards[1].clue(link.y,0)])
		lines.append(tr("CH_FIELDS_PROGRESS") % [boards[0].opened,boards[0].cells.size()-boards[0].mine_total,boards[1].opened,boards[1].cells.size()-boards[1].mine_total])
		return "\n".join(lines)
	if kind=="ADMIN_LINK": return tr("PORTAL_EXPLAIN_ON" if board().portal_enabled else "PORTAL_EXPLAIN_OFF")
	if kind in ["LOOP","LOOP_B"]:
		return tr("CH_LOOP_DONE") if loop_done else tr("CH_LOOP_COUNT")+" "+str(maxi(0,3-actions))
	if kind=="REWRITE": return tr("CH_REWRITE_GOAL")
	return ""
