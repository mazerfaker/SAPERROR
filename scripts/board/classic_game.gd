extends RefCounted
const Board = preload("res://scripts/board/state.gd")
const Profiles = preload("res://scripts/board/profiles.gd")
var board: Board
var profile: int=0
var seed_value: int=1701
var elapsed: float=0.0
var timer_enabled: bool=true
var generation_failed: bool=false
func start(next_profile: int, next_seed: int) -> void:
	profile=clampi(next_profile,0,2)
	seed_value=next_seed
	board=null
	elapsed=0.0
	generation_failed=false
func width() -> int:
	return Profiles.SIZES[profile]
func mines() -> int:
	return Profiles.MINES[profile]
func act(index: int, mode: String="reveal") -> bool:
	if index<0 or index>=width()*width() or mode not in ["reveal","flag","chord"]: return false
	if board==null:
		if mode!="reveal": return false
		var generated: Dictionary=Profiles.generate(profile,seed_value,index)
		if generated.is_empty():
			generation_failed=true
			return false
		board=Board.new(width(),width(),generated["mask"],1)
		board.reveal(index)
		generation_failed=false
		return true
	if board.finished(): return false
	var prior: PackedInt32Array=board.cells.duplicate()
	match mode:
		"reveal": board.reveal(index)
		"flag": board.flag(index)
		"chord": board.chord(index)
	return board.cells!=prior
func tick(delta: float) -> void:
	if timer_enabled and board!=null and not board.finished(): elapsed+=maxf(0.0,delta)
