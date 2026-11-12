extends Node
## Autoload "CutsceneManager": the one entry point for playing cutscenes.
##
##   await CutsceneManager.play("act1/return")   # res://cutscenes/act1/return.cut
##
## Gameplay code should ignore player input while `is_playing` is true
## (or listen to cutscene_started / cutscene_finished).

signal cutscene_started(id: String)
signal cutscene_finished(id: String, skipped: bool)

const CUTSCENE_DIR := "res://cutscenes/"
const SKIP_HOLD_SECONDS := 1.0

## When >= 0, every dialogue line auto-advances after this delay (tests, attract mode).
var auto_advance_override := -1.0

var is_playing := false
var last_skipped := false
## 0..1 while the skip button is held; hook a UI ring to this.
var skip_progress := 0.0

var dialogue: DialogueBox
var fader: ScreenFader

var _player: CutscenePlayer
var _skip_held := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	dialogue = DialogueBox.new()
	dialogue.name = "DialogueBox"
	add_child(dialogue)
	fader = ScreenFader.new()
	fader.name = "ScreenFader"
	add_child(fader)


static func resolve_path(id: String) -> String:
	if id.begins_with("res://"):
		return id
	return CUTSCENE_DIR + id + ("" if id.ends_with(".cut") else ".cut")


## Plays a cutscene and returns when it ends. Returns false (and logs every
## problem with file:line) if the script has errors or names missing actors/markers.
## `scene_root` limits actor/marker lookup; defaults to the current scene.
func play(id: String, scene_root: Node = null) -> bool:
	if is_playing:
		push_error("Cutscene '%s' requested while another is playing" % id)
		return false
	var script := CutsceneParser.parse_file(resolve_path(id))
	var ctx := CutsceneContext.new(get_tree(), scene_root if scene_root else get_tree().current_scene, dialogue, fader)
	ctx.auto_advance = auto_advance_override
	var problems := script.errors if not script.is_valid() else script.validate(ctx)
	if not problems.is_empty():
		for p in problems:
			push_error(p)
		return false

	is_playing = true
	last_skipped = false
	_skip_held = 0.0
	_player = CutscenePlayer.new()
	cutscene_started.emit(id)
	await _player.play(script, ctx)
	last_skipped = _player.skipped
	_player = null
	is_playing = false
	skip_progress = 0.0
	cutscene_finished.emit(id, last_skipped)
	return true


func skip() -> void:
	if _player:
		_player.request_skip()


## Line number of the command currently running (for debug overlays).
func current_line() -> int:
	return _player.current_line if _player else 0


func _process(delta: float) -> void:
	if not is_playing:
		return
	# Hold-to-skip uses real time so fast-forward doesn't shorten the hold.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	if Input.is_action_pressed("cutscene_skip"):
		_skip_held += real_delta
	else:
		_skip_held = 0.0
	skip_progress = clampf(_skip_held / SKIP_HOLD_SECONDS, 0.0, 1.0)
	if skip_progress >= 1.0:
		skip()


func _ensure_input_actions() -> void:
	if not InputMap.has_action("cutscene_advance"):
		InputMap.add_action("cutscene_advance")
		_add_key("cutscene_advance", KEY_ENTER)
		_add_key("cutscene_advance", KEY_SPACE)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("cutscene_advance", click)
		var pad_a := InputEventJoypadButton.new()
		pad_a.button_index = JOY_BUTTON_A
		InputMap.action_add_event("cutscene_advance", pad_a)
	if not InputMap.has_action("cutscene_skip"):
		InputMap.add_action("cutscene_skip")
		_add_key("cutscene_skip", KEY_ESCAPE)
		var pad_start := InputEventJoypadButton.new()
		pad_start.button_index = JOY_BUTTON_START
		InputMap.action_add_event("cutscene_skip", pad_start)


func _add_key(action: String, key: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
