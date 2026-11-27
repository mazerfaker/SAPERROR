extends RefCounted
# Authored challenge state, independent of campaign HP, economy and saves.
const Board = preload("res://scripts/board/state.gd")
const Validator = preload("res://scripts/solver/validator.gd")
const Rules = preload("res://scripts/board/rules.gd")
const SIZE := 5
const FIRST := 12
const MASK_A := [0,1,14,21]
const MASK_B := [0,2,10,19]
const KINDS := ["LOOP"]
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
	valid=false
	if kind not in KINDS or not add_board(MASK_A): return false
	checkpoint=board().cells.duplicate()
	valid=true
	return true
func board() -> Board:
	return boards[active_layer]
func won() -> bool:
	if not valid: return false
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
func marker(index: int) -> String:
	return "LOOP" if kind=="LOOP" and not loop_done and index in loop_zone else ""
func hidden(_index: int) -> bool:
	return false
func details() -> String:
	if kind=="LOOP":
		return tr("CH_LOOP_DONE") if loop_done else tr("CH_LOOP_COUNT")+" "+str(maxi(0,3-actions))
	return ""
