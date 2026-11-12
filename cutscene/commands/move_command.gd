extends CutsceneCommand
## move <actor> to <marker> [speed=walk|run|<metres per second>]

var _tween: Tween


func check() -> String:
	if args.size() != 3 or args[1] != "to":
		return "usage: move <actor> to <marker> [speed=walk|run|<m/s>]"
	var speed = kwargs.get("speed", "walk")
	if not (CutsceneActor.SPEEDS.has(speed) or (is_number(speed) and float(speed) > 0.0)):
		return "speed must be walk, run, or a positive number (got '%s')" % speed
	return ""


func validate(c: CutsceneContext) -> PackedStringArray:
	var errors := PackedStringArray()
	if not c.actors.has(args[0]):
		errors.append(c.actor_error(args[0], line))
	if not c.markers.has(args[2]):
		errors.append("line %d: unknown marker '%s'" % [line, args[2]])
	return errors


func _start() -> void:
	var actor := ctx.get_actor(args[0])
	var speed := CutsceneActor.resolve_speed(kwargs.get("speed", "walk"))
	_tween = actor.move_to(ctx.get_marker(args[2]).global_position, speed)
	if _tween:
		_tween.finished.connect(_complete)
	else:
		_complete()


func _cleanup() -> void:
	if _tween:
		_tween.kill()


func _apply_end_state() -> void:
	ctx.get_actor(args[0]).snap_move(ctx.get_marker(args[2]).global_position)
