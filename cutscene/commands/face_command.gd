extends CutsceneCommand
## face <actor> <actor|marker> [time=<seconds>]

var _tween: Tween


func check() -> String:
	if args.size() != 2:
		return "usage: face <actor> <actor|marker> [time=<seconds>]"
	if kwargs.has("time") and not is_number(kwargs.time):
		return "time must be a number"
	return ""


func validate(c: CutsceneContext) -> PackedStringArray:
	var errors := PackedStringArray()
	if not c.actors.has(args[0]):
		errors.append(c.actor_error(args[0], line))
	if not c.has_point(args[1]):
		errors.append(c.point_error(args[1], line))
	return errors


func _start() -> void:
	_tween = ctx.get_actor(args[0]).face_towards(ctx.get_point(args[1]), kw_float("time", -1.0))
	if _tween:
		_tween.finished.connect(_complete)
	else:
		_complete()


func _cleanup() -> void:
	if _tween:
		_tween.kill()


func _apply_end_state() -> void:
	ctx.get_actor(args[0]).snap_face(ctx.get_point(args[1]))
