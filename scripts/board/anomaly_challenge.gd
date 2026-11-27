extends RefCounted
# Authored challenge state, independent of campaign HP, economy and saves.
const Board = preload("res://scripts/board/state.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Rules = preload("res://scripts/board/rules.gd")
const SIZE := 5
const FIRST := 12
const MASK_A := [0,1,14,21]
const MASK_B := [0,2,10,19]
const KINDS := ["LOOP","DOUBLE","WATCHER","LIAR"]
const LIAR_ROWS := [0,2,4]
const DOUBLE_LINKS := [Vector2i(11,13),Vector2i(13,11)]
var kind: String = "LOOP"
var boards: Array[Board] = []
var certificates: Array[Dictionary] = []
var active_layer: int = 0
var actions: int = 0
var valid: bool = false
var loop_done: bool = false
var loop_zone: Array[int] = [0,1,2,3,4,5,6,7,8,9]
var checkpoint: PackedInt32Array
var notice: String = ""
var watcher_groups: Array[Array] = []
var watcher_log: Dictionary = {}
var watcher_closed: bool = false
var journal_open: bool = false
var sensor_values: Array[int] = []
var checksum_values: Array[int] = []
var liar_solved: bool = false
var liar_bad: int = 1
func make_mask(mines: Array) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(SIZE*SIZE)
	for i in mines: mask[int(i)]=1
	return mask
func add_board(mines: Array) -> bool:
	var mask: PackedByteArray = make_mask(mines)
	var proof: Dictionary = Validator.certify(SIZE,SIZE,mask,FIRST,[Rules.Rule.CLASSIC])
	if proof.is_empty(): return false
	var b := Board.new(SIZE,SIZE,mask,3)
	b.reveal(FIRST)
	boards.append(b)
	certificates.append(proof)
	return not b.finished()
func start(next_kind: String) -> bool:
	kind = next_kind
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
	valid=false
	if kind not in KINDS or not add_board(MASK_A): return false
	if kind=="DOUBLE" and not add_board(MASK_B): return false
	checkpoint=board().cells.duplicate()
	if kind=="WATCHER":
		var open_ids: Array[int] = []
		for i in range(board().cells.size()):
			if board().cells[i]==Board.Cell.OPEN: open_ids.append(i)
		if open_ids.size()<6: return false
		for group in range(3):
			var pair: Array[int] = [open_ids[group*2],open_ids[group*2+1]]
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
func board() -> Board:
	return boards[active_layer]
func won() -> bool:
	if not valid or (kind=="LIAR" and not liar_solved): return false
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
	if not valid or done() or board().finished() or index<0 or index>=SIZE*SIZE: return false
	var b: Board = board()
	var before: PackedInt32Array = b.cells.duplicate()
	if flag: b.flag(index)
	elif chord: b.chord(index)
	else: b.reveal(index)
	if b.cells==before: return false
	actions += 1
	notice=""
	if kind=="LOOP" and not loop_done and b.hp>0 and (actions>=3 or b.won()):
		apply_loop()
	if kind=="WATCHER" and not watcher_closed and actions>=5:
		watcher_closed=true
		notice="CH_WATCHER_CLOSED"
	return true
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
	if valid and kind=="DOUBLE" and not lost(): active_layer=1-active_layer
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
	if kind=="LIAR":
		var row: int = index/SIZE
		if LIAR_ROWS.has(row): return "S%d" % (LIAR_ROWS.find(row)+1)
	if kind=="WATCHER":
		for g in range(watcher_groups.size()):
			if watcher_groups[g].has(index): return "WATCHER G%d" % (g+1)
	if kind=="DOUBLE":
		for link in DOUBLE_LINKS:
			if index==(link.x if active_layer==0 else link.y): return "PARALLEL"
	return "LOOP" if kind=="LOOP" and not loop_done and index in loop_zone else ""
func hidden(index: int) -> bool:
	return kind=="WATCHER" and watcher_closed and watcher_log.has(index)
func details() -> String:
	if kind=="LIAR":
		var readings: Array[int] = decoded_sensors() if liar_solved else sensor_values
		return "S1 = %d | S2 = %d | S3 = %d\nS1+S2 = %d | S2+S3 = %d | S1+S3 = %d\n%s" % [readings[0],readings[1],readings[2],checksum_values[0],checksum_values[1],checksum_values[2],tr("CH_LIAR_CORRECT" if liar_solved else "CH_LIAR_SELECT")]
	if kind=="WATCHER":
		var status: String = tr("CH_WATCHER_CLOSED") if watcher_closed else tr("CH_WATCHER_COUNT")+" "+str(maxi(0,5-actions))
		var lines := PackedStringArray([status])
		for g in range(watcher_groups.size()):
			var pair := PackedStringArray()
			for index in watcher_groups[g]:
				pair.append("#%d%s" % [int(index)+1,("="+str(watcher_log[index])) if journal_open else ""])
			lines.append("G%d: %s" % [g+1," / ".join(pair)])
		return "\n".join(lines)
	if kind=="DOUBLE":
		var lines := PackedStringArray()
		for link in DOUBLE_LINKS:
			var a: Board = boards[0]
			var b: Board = boards[1]
			lines.append("A#%d: %d | B#%d: %d" % [link.x+1,a.clue(link.x,0),link.y+1,b.clue(link.y,0)])
		return "PARALLEL // "+("A" if active_layer==0 else "B")+"\n"+tr("CH_DOUBLE_LINKS")+"\n"+"\n".join(lines)+"\n"+tr("CH_DOUBLE_PROGRESS")+" A %d/21 | B %d/21" % [boards[0].opened,boards[1].opened]
	if kind=="LOOP":
		return tr("CH_LOOP_DONE") if loop_done else tr("CH_LOOP_COUNT")+" "+str(maxi(0,3-actions))
	return ""
