extends Node
## Headless test suite. Run:
##   godot --headless --path . res://tests/run_tests.tscn
## Exits with code 0 on success, 1 on any failure.

const DEMO := preload("res://tests/demo/demo.tscn")

var _failures := 0
var _checks := 0


func _ready() -> void:
	Engine.time_scale = 8.0
	CutsceneManager.auto_advance_override = 0.05

	_test_tokenizer()
	_test_parse_errors()
	_test_all_cutscene_files_parse()
	await _test_validation()

	var watched := await _run_demo(false)
	_check(watched.played and not watched.skipped, "demo plays to the end")
	_check(watched.hero_pos.distance_to(Vector3(0, 0, 1)) < 0.01, "hero ends at 'well' (got %s)" % watched.hero_pos)
	_check(watched.mira_pos.distance_to(Vector3(6, 0, -4)) < 0.01, "mira ends at 'gate' (got %s)" % watched.mira_pos)
	_check(is_equal_approx(watched.fade, 1.0), "screen ends faded out")
	_check(not watched.dialogue_open, "dialogue box closed at end")

	var skipped := await _run_demo(true)
	_check(skipped.played and skipped.skipped, "demo can be skipped")
	_check(skipped.elapsed < watched.elapsed * 0.5, "skip ends early (%.2fs vs %.2fs)" % [skipped.elapsed, watched.elapsed])
	for key in ["hero_pos", "mira_pos", "hero_yaw", "mira_yaw", "fade", "dialogue_open"]:
		_check(_same(watched[key], skipped[key]), "skip end state matches watched: %s (%s vs %s)" % [key, watched[key], skipped[key]])

	print("\n%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures else 0)


func _test_tokenizer() -> void:
	var s := CutsceneParser.parse_text('say mira "Hi, \\"you\\"! a=b" emotion=sad auto=1 # comment')
	_check(s.is_valid(), "tokenizer: valid say line")
	if s.is_valid():
		var e: Dictionary = s.entries[0]
		_check(e.args == ["mira", 'Hi, "you"! a=b'], "tokenizer: quoted text kept whole (%s)" % [e.args])
		_check(e.kwargs == {"emotion": "sad", "auto": "1"}, "tokenizer: kwargs parsed (%s)" % e.kwargs)
	var q := CutsceneParser.parse_text('say hero "x" note="two words"')
	_check(q.is_valid() and q.entries[0].kwargs.get("note") == "two words", "tokenizer: quoted kwarg value")


func _test_parse_errors() -> void:
	var s := CutsceneParser.parse_text("wiat 1\nmove hero well\n\nfade sideways 1\nsay hero \"unterminated\nwait 0.5")
	_check(s.errors.size() == 4, "parse errors: 4 bad lines reported (got %d: %s)" % [s.errors.size(), s.errors])
	_check(s.entries.size() == 1, "parse errors: good line still parsed")
	var joined := "\n".join(s.errors)
	for ln in [":1:", ":2:", ":4:", ":5:"]:
		_check(joined.contains(ln), "parse errors: line number %s reported" % ln)


func _test_all_cutscene_files_parse() -> void:
	for path in _find_files("res://cutscenes", ".cut"):
		var s := CutsceneParser.parse_file(path)
		_check(s.is_valid(), "%s parses %s" % [path, s.errors])


func _test_validation() -> void:
	var demo := DEMO.instantiate()
	demo.autoplay = false
	add_child(demo)
	await get_tree().process_frame
	var ctx := CutsceneContext.new(get_tree(), demo, CutsceneManager.dialogue, CutsceneManager.fader)
	var good := CutsceneParser.parse_file("res://cutscenes/demo/village.cut").validate(ctx)
	_check(good.is_empty(), "demo cutscene validates against demo scene %s" % good)
	var bad := CutsceneParser.parse_text("move bob to well\nface hero nowhere\nsay ghost \"boo\"", "bad.cut").validate(ctx)
	_check(bad.size() == 3, "validation: unknown actor / marker caught (%s)" % bad)
	demo.queue_free()
	await get_tree().process_frame


func _run_demo(skip: bool) -> Dictionary:
	var demo := DEMO.instantiate()
	demo.autoplay = false
	add_child(demo)
	await get_tree().process_frame
	if skip:
		get_tree().create_timer(1.5).timeout.connect(CutsceneManager.skip)
	var start := Time.get_ticks_msec()
	var played: bool = await CutsceneManager.play("demo/village", demo)
	var hero: Node3D = demo.get_node("Hero")
	var mira: Node3D = demo.get_node("Mira")
	var result := {
		"played": played,
		"skipped": CutsceneManager.last_skipped,
		"elapsed": (Time.get_ticks_msec() - start) / 1000.0,
		"hero_pos": hero.global_position,
		"mira_pos": mira.global_position,
		"hero_yaw": wrapf(hero.rotation.y, -PI, PI),
		"mira_yaw": wrapf(mira.rotation.y, -PI, PI),
		"fade": CutsceneManager.fader.get_alpha(),
		"dialogue_open": CutsceneManager.dialogue.is_open(),
	}
	demo.queue_free()
	CutsceneManager.fader.set_alpha(0.0)
	await get_tree().process_frame
	return result


func _same(a, b) -> bool:
	if a is Vector3:
		return a.distance_to(b) < 0.01
	if a is float:
		return absf(a - b) < 0.01
	return a == b


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("  ok   ", what)
	else:
		_failures += 1
		printerr("  FAIL ", what)


func _find_files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_find_files(dir.path_join(sub), ext))
	return out
