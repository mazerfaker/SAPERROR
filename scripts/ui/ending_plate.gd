extends Control
# Original final scene illustrations; visual-only, no changes to campaign state.
const ART := {
	"SHUTDOWN": preload("res://assets/narrative/endings/shutdown.svg"),
	"CONTAINMENT": preload("res://assets/narrative/endings/containment.svg"),
	"REWRITE": preload("res://assets/narrative/endings/rewrite.svg")
}
const TINTS := {"SHUTDOWN":Color("d36c60"),"CONTAINMENT":Color("e5b86c"),"REWRITE":Color("a1d8a0")}
const DURATIONS := {"SHUTDOWN":0.65,"CONTAINMENT":0.50,"REWRITE":0.75}
var ending_id: String="SHUTDOWN"
var reduced_motion: bool=false
var progress: float=1.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	progress=1.0 if reduced_motion else 0.0
	set_process(not reduced_motion and ART.has(ending_id))
	queue_redraw()
func _process(delta: float) -> void:
	progress=minf(1.0,progress+maxf(delta,0.0)/float(DURATIONS.get(ending_id,0.65)))
	queue_redraw()
	if progress>=1.0: set_process(false)
func _draw() -> void:
	if not ART.has(ending_id): return
	var tex: Texture2D=ART[ending_id]
	var extent: Vector2=tex.get_size()
	extent*=minf(size.x/extent.x,size.y/extent.y)
	var rect:=Rect2((size-extent)*0.5,extent)
	var ease: float=progress*progress*(3.0-2.0*progress)
	var opacity: float=lerpf(0.55,1.0,ease)
	if ending_id=="SHUTDOWN": opacity=lerpf(1.0,0.78,ease)
	draw_texture_rect(tex,rect,false,Color(1,1,1,opacity))
	if not reduced_motion and progress<1.0 and ending_id!="SHUTDOWN":
		var tint: Color=TINTS[ending_id]
		tint.a=0.14*(1.0-progress)
		if ending_id=="CONTAINMENT":
			var inset: float=rect.size.x*0.09*(1.0-ease)
			draw_rect(rect.grow(-inset),tint,false,2.0)
		else:
			var y: float=rect.end.y-rect.size.y*ease
			draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),tint,2.0)
