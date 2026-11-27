extends RefCounted
# Read-only shared style resources. Callers must not mutate cached styles.
const LIMIT: int=128
var entries: Dictionary={}
var allocations: int=0
func get_style(fill: Color, edge: Color, width: int=2, compact: bool=true) -> StyleBoxFlat:
	var key: Array=[fill,edge,width,compact]
	if entries.has(key): return entries[key] as StyleBoxFlat
	var style:=StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=edge
	style.set_border_width_all(width)
	if compact:
		style.content_margin_left=2
		style.content_margin_right=2
		style.content_margin_top=2
		style.content_margin_bottom=2
	allocations+=1
	# Fixed palette normally fits well below this cap. Never evict live resources.
	if entries.size()<LIMIT: entries[key]=style
	return style
