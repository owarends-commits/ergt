class_name CutsceneParser
extends RefCounted
## Parses .cut text into a CutsceneScript.
##
## Syntax, one command per line:
##   name arg arg "quoted arg" key=value key="quoted value"   # comment

const COMMANDS := {
	"wait": preload("res://cutscene/commands/wait_command.gd"),
	"move": preload("res://cutscene/commands/move_command.gd"),
	"face": preload("res://cutscene/commands/face_command.gd"),
	"say": preload("res://cutscene/commands/say_command.gd"),
	"fade": preload("res://cutscene/commands/fade_command.gd"),
}


static func parse_file(path: String) -> CutsceneScript:
	if not FileAccess.file_exists(path):
		var missing := CutsceneScript.new()
		missing.source = path
		missing.errors.append("%s: file not found" % path)
		return missing
	return parse_text(FileAccess.get_file_as_string(path), path)


static func parse_text(text: String, source := "<text>") -> CutsceneScript:
	var script := CutsceneScript.new()
	script.source = source
	var lines := text.split("\n")
	for i in lines.size():
		var line_no := i + 1
		var tokens := _tokenize(lines[i])
		if tokens.has("error"):
			script.errors.append("%s:%d: %s" % [source, line_no, tokens.error])
			continue
		var words: Array = tokens.words
		if words.is_empty():
			continue

		var entry := {"name": words[0].text, "line": line_no, "args": [], "kwargs": {}}
		for w in words.slice(1):
			if w.kv:
				entry.kwargs[w.text.substr(0, w.text.find("="))] = w.value
			else:
				entry.args.append(w.text)

		if not COMMANDS.has(entry.name):
			script.errors.append("%s:%d: unknown command '%s' (known: %s)"
				% [source, line_no, entry.name, ", ".join(COMMANDS.keys())])
			continue
		var problem := make_command(entry).check()
		if problem != "":
			script.errors.append("%s:%d: %s" % [source, line_no, problem])
			continue
		script.entries.append(entry)
	return script


static func make_command(entry: Dictionary) -> CutsceneCommand:
	var cmd: CutsceneCommand = COMMANDS[entry.name].new()
	cmd.name = entry.name
	cmd.line = entry.line
	cmd.args = entry.args.duplicate()
	cmd.kwargs = entry.kwargs.duplicate()
	return cmd


## Splits a line into words. Each word: {text, kv, value}. Quotes group text,
## \" escapes a quote, and # starts a comment outside quotes. A word that
## starts with a quote is always positional, so "a=b" in dialogue stays text.
static func _tokenize(line: String) -> Dictionary:
	var words := []
	var cur := ""
	var in_word := false
	var in_quotes := false
	var starts_quoted := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if in_quotes:
			if c == "\\" and i + 1 < line.length():
				cur += line[i + 1]
				i += 1
			elif c == "\"":
				in_quotes = false
			else:
				cur += c
		elif c == "\"":
			if not in_word:
				starts_quoted = true
			in_quotes = true
			in_word = true
		elif c == "#":
			break
		elif c == " " or c == "\t" or c == "\r":
			if in_word:
				words.append(_word(cur, starts_quoted))
				cur = ""
				in_word = false
				starts_quoted = false
		else:
			cur += c
			in_word = true
		i += 1
	if in_quotes:
		return {"error": "unterminated quote"}
	if in_word:
		words.append(_word(cur, starts_quoted))
	return {"words": words}


static func _word(text: String, starts_quoted: bool) -> Dictionary:
	var eq := text.find("=")
	var key := text.substr(0, eq) if eq > 0 and not starts_quoted else ""
	var is_kv := key != "" and key.is_valid_identifier()
	return {"text": text, "kv": is_kv, "value": text.substr(eq + 1) if is_kv else ""}
