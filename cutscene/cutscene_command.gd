class_name CutsceneCommand
extends RefCounted
## Base class for one line of a cutscene script.
##
## Lifecycle:
##   check()            parse time: are the arguments well formed? ("" = ok)
##   validate(ctx)      load time: do the actors / markers it names exist?
##   run(ctx)           play it; returns when the command is done
##   skip(ctx)          jump straight to the end state (also works if never started)
##
## Subclasses override _start / _apply_end_state / _cleanup and call
## _complete() when they finish on their own.

signal done

var name := ""
var line := 0
var args: Array = []
var kwargs: Dictionary = {}

var ctx: CutsceneContext
var _finished := false


func check() -> String:
	return ""


func validate(_ctx: CutsceneContext) -> PackedStringArray:
	return PackedStringArray()


func run(context: CutsceneContext) -> void:
	ctx = context
	_start()
	if not _finished:
		await done


func skip(context: CutsceneContext) -> void:
	if _finished:
		return
	ctx = context
	_cleanup()
	_apply_end_state()
	_complete()


# --- overridables -----------------------------------------------------------

func _start() -> void:
	_complete()


func _apply_end_state() -> void:
	pass


func _cleanup() -> void:
	pass


# --- helpers ----------------------------------------------------------------

func _complete() -> void:
	if _finished:
		return
	_finished = true
	done.emit()


func is_finished() -> bool:
	return _finished


func kw_float(key: String, default: float) -> float:
	return float(kwargs[key]) if kwargs.has(key) else default


static func is_number(value) -> bool:
	return str(value).is_valid_float()
