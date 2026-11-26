extends Control
const Board = preload("res://scripts/board/state.gd")
const Generator = preload("res://scripts/board/generator.gd")
var board: Board
var certificate: Dictionary = {}
var buttons: Array[Button] = []
var seed_input: LineEdit
var title_label: Label
var instructions: Label
var status: Label
var counts: Label
var new_button: Button
var language: Button
var seed_label: Label
var last_hits: int = 0
var message_key: String = "CORE_READY"
var is_uk: bool = true
func _ready() -> void:
	TranslationServer.set_locale("uk")
	var background := ColorRect.new()
	background.color = Color("101714")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	var brand := Label.new()
	brand.text = "SAPERROR"
	brand.add_theme_font_size_override("font_size", 42)
	col.add_child(brand)
	title_label = Label.new()
	col.add_child(title_label)
	var tools := HBoxContainer.new()
	col.add_child(tools)
	seed_label = Label.new()
	tools.add_child(seed_label)
	seed_input = LineEdit.new()
	seed_input.text = "1701"
	seed_input.custom_minimum_size.x = 155
	tools.add_child(seed_input)
	new_button = Button.new()
	new_button.pressed.connect(_reset)
	tools.add_child(new_button)
	language = Button.new()
	language.pressed.connect(_language)
	tools.add_child(language)
	counts = Label.new()
	col.add_child(counts)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	col.add_child(grid)
	for i in range(64):
		var button := Button.new()
		button.custom_minimum_size = Vector2(58, 52)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_reveal.bind(i))
		button.gui_input.connect(_cell_input.bind(i))
		grid.add_child(button)
		buttons.append(button)
	status = Label.new()
	col.add_child(status)
	instructions = Label.new()
	col.add_child(instructions)
	_reset()
func _language() -> void:
	is_uk = not is_uk
	TranslationServer.set_locale("uk" if is_uk else "en")
	_refresh()
func _reset() -> void:
	board = null
	certificate.clear()
	last_hits = 0
	message_key = "CORE_READY"
	_refresh()
func _reveal(i: int) -> void:
	if board == null:
		if not seed_input.text.is_valid_int():
			message_key = "CORE_SEED_BAD"
			_refresh()
			return
		var generated: Dictionary = Generator.generate(seed_input.text.to_int(), i)
		if generated.is_empty():
			message_key = "CORE_FAIL"
			_refresh()
			return
		certificate = generated["certificate"]
		board = Board.new(8, 8, generated["mask"], 3)
	board.reveal(i)
	_after_action()
func _cell_input(event: InputEvent, i: int) -> void:
	if board == null or board.finished(): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			board.flag(i)
			buttons[i].accept_event()
			_after_action()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			board.chord(i)
			buttons[i].accept_event()
			_after_action()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and board.cells[i] == Board.Cell.OPEN:
		board.chord(i)
		buttons[i].accept_event()
		_after_action()
func _after_action() -> void:
	message_key = "CORE_ACTIVE"
	if board.hits > last_hits: message_key = "CORE_HIT"
	last_hits = board.hits
	if board.won(): message_key = "CORE_WIN"
	elif board.hp <= 0: message_key = "CORE_LOSS"
	_refresh()
func _refresh() -> void:
	title_label.text = tr("CORE_SUB")
	instructions.text = tr("CORE_HINT")
	seed_label.text = tr("CORE_SEED")
	new_button.text = tr("CORE_NEW")
	language.text = "EN" if is_uk else "UA"
	status.text = tr(message_key)
	counts.text = "%s: %d   |   %s: %d / 54" % [tr("CORE_HP"), 3 if board == null else board.hp, tr("CORE_OPEN"), 0 if board == null else board.opened]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		var state: int = Board.Cell.CLOSED if board == null else board.cells[i]
		var description: String = tr("CORE_CLOSED")
		button.text = "·"
		button.modulate = Color.WHITE
		button.disabled = board != null and board.finished()
		if state == Board.Cell.OPEN:
			var n: int = board.clue(i, board.rule)
			button.text = str(n)
			button.modulate = Color("a1d8a0")
			description = str(n)
		elif state == Board.Cell.FLAG:
			button.text = "⚑"
			button.modulate = Color("e5b86c")
			description = tr("CORE_FLAG")
		elif state == Board.Cell.NEUTRALIZED:
			button.text = "×"
			button.modulate = Color("d36c60")
			description = tr("CORE_NEUTRAL")
		button.tooltip_text = "%s %d: %s" % [tr("CORE_CELL"), i + 1, description]
