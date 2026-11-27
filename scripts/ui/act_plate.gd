extends Control
# Authored vector illustration. Localized story and navigation are separate live controls.
const ART := [
	preload("res://assets/narrative/acts/boot.svg"),
	preload("res://assets/narrative/acts/corruption.svg"),
	preload("res://assets/narrative/acts/echo.svg"),
	preload("res://assets/narrative/acts/admin.svg")
]
const TINTS := [Color("a1d8a0"),Color("e5b86c"),Color("a0c2c4"),Color("d36c60")]
var act_index: int=0
var reduced_motion: bool=false
var reveal: float=1.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	reveal=1.0 if reduced_motion else 0.0
	set_process(not reduced_motion)
	queue_redraw()
func _process(delta: float) -> void:
	reveal=minf(1.0,reveal+maxf(0.0,delta)/0.42)
	queue_redraw()
	if reveal>=1.0: set_process(false)
func _draw() -> void:
	if act_index<0 or act_index>=ART.size(): return
	var tex: Texture2D=ART[act_index]
	var extent: Vector2=tex.get_size()
	var ratio: float=minf(size.x/extent.x,size.y/extent.y)
	extent*=ratio
	var tint:=Color(1,1,1,lerpf(0.55,1.0,reveal))
	draw_texture_rect(tex,Rect2((size-extent)*0.5,extent),false,tint)
