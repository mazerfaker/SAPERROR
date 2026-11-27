extends Control
# Original vector assets rendered inside the existing CRT. No gameplay effects.
const ART := {
	"WATCHER": preload("res://assets/narrative/bosses/watcher.svg"),
	"LIAR": preload("res://assets/narrative/bosses/liar.svg"),
	"LOOP": preload("res://assets/narrative/bosses/loop.svg"),
	"ADMIN": preload("res://assets/narrative/bosses/admin.svg")
}
const TINTS := {"WATCHER":Color("a1d8a0"),"LIAR":Color("e5b86c"),"LOOP":Color("a0c2c4"),"ADMIN":Color("d36c60")}
var boss_id: String="WATCHER"
var reduced_motion: bool=false
var phase: float=0.0
static func resolve(kind: String) -> String:
	if kind in ["LOOP","LOOP_B"]: return "LOOP"
	if kind=="ADMIN_LINK": return "ADMIN"
	return kind if ART.has(kind) else ""
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_process(not reduced_motion)
	queue_redraw()
func _process(delta: float) -> void:
	phase=fposmod(phase+delta*0.16,1.0)
	queue_redraw()
func _draw() -> void:
	if not ART.has(boss_id): return
	var tex: Texture2D=ART[boss_id]
	var scale_factor: float=minf(size.x/320.0,size.y/256.0)
	var extent:=Vector2(320,256)*scale_factor
	var rect:=Rect2((size-extent)*0.5,extent)
	draw_texture_rect(tex,rect,false)
	if not reduced_motion:
		var tint: Color=TINTS[boss_id]
		tint.a=0.13
		var y: float=rect.position.y+rect.size.y*phase
		draw_line(Vector2(rect.position.x+3,y),Vector2(rect.end.x-3,y),tint,maxf(1.0,scale_factor*2.0))
