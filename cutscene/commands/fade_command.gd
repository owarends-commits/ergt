extends CutsceneCommand
## fade in|out <seconds> [color=black|white|#rrggbb]
##   fade out = to a solid colour, fade in = back to the scene.

var _tween: Tween


func check() -> String:
	if args.size() != 2 or not (args[0] in ["in", "out"]) or not is_number(args[1]):
		return "usage: fade in|out <seconds> [color=black|white|#rrggbb]"
	const INVALID := Color(1, 0, 1, 0.123)
	if kwargs.has("color") and Color.from_string(kwargs.color, INVALID) == INVALID:
		return "unknown color '%s'" % kwargs.color
	return ""


func _target_alpha() -> float:
	return 1.0 if args[0] == "out" else 0.0


func _color() -> Color:
	return Color.from_string(kwargs.get("color", "black"), Color.BLACK)


func _start() -> void:
	_tween = ctx.fader.fade(_target_alpha(), float(args[1]), _color())
	if _tween:
		_tween.finished.connect(_complete)
	else:
		_complete()


func _cleanup() -> void:
	if _tween:
		_tween.kill()


func _apply_end_state() -> void:
	ctx.fader.set_alpha(_target_alpha(), _color())
