extends RefCounted
static func physical(event: InputEventKey) -> int:
	return event.physical_keycode if event.physical_keycode!=0 else event.keycode
static func focus_style(contrast: bool) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0,0,0,0)
	style.border_color=Color.WHITE if contrast else Color("f0c37b")
	style.set_border_width_all(4)
	return style
static func readable(color: Color, contrast: bool) -> Color:
	return color.lightened(0.55) if contrast else color
static func focus_first(node: Node) -> bool:
	if node is Button and node.is_visible_in_tree() and not node.disabled and node.focus_mode!=Control.FOCUS_NONE:
		node.grab_focus()
		return true
	for child in node.get_children():
		if focus_first(child): return true
	return false
static func focus_tiles(tiles: Array[Button]) -> bool:
	for tile in tiles:
		if is_instance_valid(tile) and not tile.disabled and tile.is_visible_in_tree():
			tile.grab_focus()
			return true
	return false
static func grid_key(event: InputEvent, tiles: Array[Button], index: int, columns: int) -> bool:
	if not event is InputEventKey or not event.pressed or event.alt_pressed or event.ctrl_pressed or event.meta_pressed: return false
	var key: int=physical(event)
	if key not in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]: return false
	if columns<=0 or index<0 or index>=tiles.size(): return false
	var step: int=1 if key==KEY_RIGHT else (-1 if key==KEY_LEFT else (columns if key==KEY_DOWN else -columns))
	var target: int=index+step
	while target>=0 and target<tiles.size():
		if absi(step)==1 and target/columns!=index/columns: break
		if is_instance_valid(tiles[target]) and not tiles[target].disabled and tiles[target].is_visible_in_tree():
			tiles[target].grab_focus()
			break
		target+=step
	tiles[index].accept_event()
	return true
