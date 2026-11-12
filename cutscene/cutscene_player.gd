class_name CutscenePlayer
extends RefCounted
## Runs a CutsceneScript's commands in order.
##
## Skipping finishes the current command instantly and then applies the end
## state of every remaining command, so the world ends up exactly as if the
## scene had been watched to the end.

var skipped := false
var current_line := 0

var _commands: Array[CutsceneCommand] = []
var _current: CutsceneCommand
var _ctx: CutsceneContext


func play(script: CutsceneScript, ctx: CutsceneContext) -> void:
	_ctx = ctx
	_commands = script.instantiate()
	var i := 0
	while i < _commands.size() and not skipped:
		_current = _commands[i]
		current_line = _current.line
		await _current.run(ctx)
		# Keep the dialogue box up between consecutive lines; hide it otherwise.
		var next_is_say := i + 1 < _commands.size() and _commands[i + 1].name == "say"
		if not next_is_say:
			ctx.dialogue.hide_box()
		i += 1
	if skipped:
		for j in range(i, _commands.size()):
			_commands[j].skip(ctx)
		ctx.dialogue.hide_box()
	_current = null


func request_skip() -> void:
	if skipped or _current == null:
		return
	skipped = true
	_current.skip(_ctx)
