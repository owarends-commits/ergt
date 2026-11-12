class_name CutsceneScript
extends RefCounted
## A parsed .cut file: plain data entries plus any parse errors.
## Commands are instantiated fresh for every playback.

var source := ""
var entries: Array[Dictionary] = []
var errors := PackedStringArray()


func is_valid() -> bool:
	return errors.is_empty()


func instantiate() -> Array[CutsceneCommand]:
	var out: Array[CutsceneCommand] = []
	for e in entries:
		out.append(CutsceneParser.make_command(e))
	return out


## Checks every command against the scene (actors, markers exist).
func validate(ctx: CutsceneContext) -> PackedStringArray:
	var problems := PackedStringArray()
	for msg in ctx.setup_errors:
		problems.append("%s: %s" % [source, msg])
	for cmd in instantiate():
		for msg in cmd.validate(ctx):
			problems.append("%s:%s" % [source, msg.trim_prefix("line ")])
	return problems
