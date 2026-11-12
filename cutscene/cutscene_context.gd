class_name CutsceneContext
extends RefCounted
## Everything a command can touch while a cutscene runs: actors, markers,
## and the UI layers. Built fresh each time a cutscene starts.

const NARRATOR := "narrator"

var tree: SceneTree
var scene: Node
var dialogue: DialogueBox
var fader: ScreenFader
## When >= 0, dialogue lines auto-advance after this many seconds (tests, demos).
var auto_advance := -1.0

var actors := {}   # actor_id -> CutsceneActor
var markers := {}  # marker name -> Marker3D
var setup_errors := PackedStringArray()


func _init(p_tree: SceneTree, p_scene: Node, p_dialogue: DialogueBox, p_fader: ScreenFader) -> void:
	tree = p_tree
	scene = p_scene
	dialogue = p_dialogue
	fader = p_fader

	for node in tree.get_nodes_in_group(CutsceneActor.GROUP):
		var actor := node as CutsceneActor
		if scene and not scene.is_ancestor_of(actor):
			continue
		if actors.has(actor.actor_id):
			setup_errors.append("duplicate actor id '%s'" % actor.actor_id)
		actors[actor.actor_id] = actor

	if scene:
		for node in scene.find_children("*", "Marker3D", true, false):
			var key := String(node.name)
			if markers.has(key):
				setup_errors.append("duplicate marker name '%s'" % key)
			markers[key] = node


func get_actor(id: String) -> CutsceneActor:
	return actors.get(id)


func get_marker(id: String) -> Marker3D:
	return markers.get(id)


func has_point(id: String) -> bool:
	return actors.has(id) or markers.has(id)


## World position of an actor or a marker, for commands like `face`.
func get_point(id: String) -> Vector3:
	if actors.has(id):
		return actors[id].body.global_position
	return markers[id].global_position


func actor_error(id: String, line: int) -> String:
	return "line %d: unknown actor '%s' (known: %s)" % [line, id, ", ".join(actors.keys())]


func point_error(id: String, line: int) -> String:
	return "line %d: '%s' is not an actor or marker in this scene" % [line, id]
