class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue box with typewriter text.
##
## Press "cutscene_advance" while text is typing to show it all; press again
## to move on. Built in code so it has no scene dependencies; restyle freely.

signal typing_finished
signal line_finished

const CHARS_PER_SECOND := 45.0
## Extra pause after punctuation, in seconds, so lines read with rhythm.
const PUNCTUATION_PAUSE := {".": 0.22, "!": 0.22, "?": 0.22, ",": 0.08, ";": 0.1, ":": 0.1}

var _panel: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _arrow: Label

var _plain := ""
var _typing := false
var _waiting := false
var _auto := -1.0
var _char_timer := 0.0
var _auto_timer := 0.0
var _arrow_phase := 0.0


func _ready() -> void:
	layer = 90
	_build()
	hide_box()


func is_open() -> bool:
	return _panel.visible


func is_typing() -> bool:
	return _typing


func show_line(speaker: String, text: String, auto := -1.0) -> void:
	_panel.visible = true
	_name_label.text = speaker
	_name_label.visible = speaker != ""
	_text.text = text
	_plain = _text.get_parsed_text()
	_text.visible_characters = 0
	_typing = true
	_waiting = false
	_auto = auto
	_char_timer = 0.0
	_arrow.visible = false


func hide_box() -> void:
	_panel.visible = false
	_typing = false
	_waiting = false


func _process(delta: float) -> void:
	if _typing:
		_char_timer -= delta
		while _typing and _char_timer <= 0.0:
			_text.visible_characters += 1
			if _text.visible_characters >= _plain.length():
				_finish_typing()
				break
			var c := _plain[_text.visible_characters - 1]
			_char_timer += 1.0 / CHARS_PER_SECOND + PUNCTUATION_PAUSE.get(c, 0.0)
	elif _waiting:
		if _auto >= 0.0:
			_auto_timer += delta
			if _auto_timer >= _auto:
				_advance()
		else:
			_arrow_phase += delta * 5.0
			_arrow.modulate.a = 0.55 + 0.45 * sin(_arrow_phase)


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible or not event.is_action_pressed("cutscene_advance"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_finish_typing()
	elif _waiting:
		_advance()


func _finish_typing() -> void:
	_text.visible_characters = -1
	_typing = false
	_waiting = true
	_auto_timer = 0.0
	_arrow.visible = _auto < 0.0
	typing_finished.emit()


func _advance() -> void:
	_waiting = false
	_arrow.visible = false
	line_finished.emit()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 80
	_panel.offset_right = -80
	_panel.offset_top = -190
	_panel.offset_bottom = -32
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.88)
	style.border_color = Color(1, 1, 1, 0.18)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
	vbox.add_child(_name_label)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 24)
	vbox.add_child(_text)

	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_arrow)
