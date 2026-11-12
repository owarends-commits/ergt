extends CutsceneCommand
## say <actor|narrator> "<text>" [emotion=<name>] [auto=<seconds>]
##
## Waits for the player to advance, or for `auto` seconds after the text
## finishes typing. `emotion` is accepted now and drives portraits in M2.

var _actor: CutsceneActor


func check() -> String:
	if args.size() != 2:
		return "usage: say <actor|narrator> \"<text>\" [emotion=<name>] [auto=<seconds>]"
	if kwargs.has("auto") and not is_number(kwargs.auto):
		return "auto must be a number of seconds"
	return ""


func validate(c: CutsceneContext) -> PackedStringArray:
	if args[0] != CutsceneContext.NARRATOR and not c.actors.has(args[0]):
		return PackedStringArray([c.actor_error(args[0], line)])
	return PackedStringArray()


func _start() -> void:
	_actor = ctx.get_actor(args[0])
	var speaker := _actor.display_name if _actor else ""
	var auto := kw_float("auto", ctx.auto_advance)
	ctx.dialogue.typing_finished.connect(_stop_talking, CONNECT_ONE_SHOT)
	ctx.dialogue.line_finished.connect(_complete, CONNECT_ONE_SHOT)
	if _actor:
		_actor.set_talking(true)
	ctx.dialogue.show_line(speaker, args[1], auto)


func _stop_talking() -> void:
	if _actor:
		_actor.set_talking(false)


func _cleanup() -> void:
	if ctx.dialogue.typing_finished.is_connected(_stop_talking):
		ctx.dialogue.typing_finished.disconnect(_stop_talking)
	if ctx.dialogue.line_finished.is_connected(_complete):
		ctx.dialogue.line_finished.disconnect(_complete)
	ctx.dialogue.hide_box()


func _apply_end_state() -> void:
	var actor := ctx.get_actor(args[0])
	if actor:
		actor.set_talking(false)
