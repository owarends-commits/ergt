extends Node3D
## Plays a cutscene on start. Press R afterwards to replay.

@export var autoplay := true
@export var cutscene := "demo/village"

@onready var _hint: Label = $UI/Hint


func _ready() -> void:
	_hint.text = "Enter: advance    Hold Esc: skip"
	if autoplay:
		_play()


func _play() -> void:
	await CutsceneManager.play(cutscene, self)
	_hint.text = "Cutscene finished%s.  Press R to replay." % (" (skipped)" if CutsceneManager.last_skipped else "")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R and not CutsceneManager.is_playing:
		get_tree().reload_current_scene()
