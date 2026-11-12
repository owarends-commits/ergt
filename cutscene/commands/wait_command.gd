extends CutsceneCommand
## wait <seconds>


func check() -> String:
	if args.size() != 1 or not is_number(args[0]) or float(args[0]) < 0.0:
		return "usage: wait <seconds>"
	return ""


func _start() -> void:
	ctx.tree.create_timer(float(args[0])).timeout.connect(_complete)
