class_name CutsceneActor
extends Node
## Add this node as a child of any 3D character (CharacterBody3D, Node3D, ...)
## to make it controllable from cutscene scripts.
##
## If an AnimationPlayer is assigned, the idle / walk / run / talk animations
## are played (with blending). Without one, a light procedural bob on `visual`
## keeps placeholder characters from sliding around stiffly.

const GROUP := &"cutscene_actor"
const SPEEDS := {"walk": 1.6, "run": 4.0}
const BLEND_TIME := 0.15

## Id used in scripts. Defaults to the parent's name in snake_case.
@export var actor_id := ""
## Name shown in the dialogue box. Defaults to the parent's name.
@export var display_name := ""
@export var animation_player: AnimationPlayer
@export var idle_animation := &"idle"
@export var walk_animation := &"walk"
@export var run_animation := &"run"
@export var talk_animation := &"talk"
## Optional mesh/visual child for the procedural bob when there are no animations.
@export var visual: Node3D
## Seconds to turn on the spot before walking / when facing something.
@export var turn_time := 0.25

var body: Node3D

var _moving := false
var _move_speed := 0.0
var _talking := false
var _phase := 0.0
var _visual_base := Vector3.ZERO


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	body = get_parent() as Node3D
	if body == null:
		push_error("CutsceneActor must be a child of a Node3D")
		return
	if actor_id == "":
		actor_id = String(body.name).to_snake_case()
	if display_name == "":
		display_name = String(body.name)
	if visual:
		_visual_base = visual.position
	play_anim(idle_animation)


func _process(delta: float) -> void:
	if visual == null or _has_anims():
		return
	# Procedural life for placeholder characters: footstep bob + talk wobble.
	var target_pos := _visual_base
	var target_scale := Vector3.ONE
	if _moving:
		_phase += delta * _move_speed * 3.0
		target_pos.y += absf(sin(_phase)) * 0.07
	elif _talking:
		_phase += delta * 14.0
		target_scale = Vector3(1.0, 1.0 + sin(_phase) * 0.025, 1.0)
	else:
		_phase += delta * 1.8
		target_scale = Vector3(1.0, 1.0 + sin(_phase) * 0.008, 1.0)  # breathing
	var w := 1.0 - exp(-delta * 18.0)
	visual.position = visual.position.lerp(target_pos, w)
	visual.scale = visual.scale.lerp(target_scale, w)


# --- movement ---------------------------------------------------------------

static func resolve_speed(value) -> float:
	var s := str(value)
	return SPEEDS[s] if SPEEDS.has(s) else float(s)


## Turn toward the target, walk there with eased start/stop, end in idle.
## Returns null if already there.
func move_to(target: Vector3, speed: float) -> Tween:
	var flat := _flat(target - body.global_position)
	var dist := body.global_position.distance_to(target)
	if dist < 0.01:
		return null
	var tween := body.create_tween()
	if flat.length() > 0.01:
		tween.tween_property(body, "rotation:y", _yaw_towards(flat), turn_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_begin_move.bind(speed))
	# Sine in-out gives a natural accelerate / decelerate instead of a slide.
	tween.tween_property(body, "global_position", target, dist / speed) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_end_move)
	return tween


func snap_move(target: Vector3) -> void:
	var flat := _flat(target - body.global_position)
	if flat.length() > 0.01:
		body.rotation.y = _yaw_towards(flat)
	body.global_position = target
	_end_move()


func face_towards(point: Vector3, duration := -1.0) -> Tween:
	var flat := _flat(point - body.global_position)
	if flat.length() < 0.01:
		return null
	var tween := body.create_tween()
	tween.tween_property(body, "rotation:y", _yaw_towards(flat), turn_time if duration < 0 else duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func snap_face(point: Vector3) -> void:
	var flat := _flat(point - body.global_position)
	if flat.length() > 0.01:
		body.rotation.y = _yaw_towards(flat)


# --- animation --------------------------------------------------------------

func set_talking(on: bool) -> void:
	_talking = on
	if not _moving:
		play_anim(talk_animation if on else idle_animation)


func play_anim(anim: StringName) -> void:
	if _has_anims() and animation_player.has_animation(anim):
		animation_player.play(anim, BLEND_TIME)


func _begin_move(speed: float) -> void:
	_moving = true
	_move_speed = speed
	play_anim(run_animation if speed >= SPEEDS.run else walk_animation)


func _end_move() -> void:
	_moving = false
	play_anim(talk_animation if _talking else idle_animation)


func _has_anims() -> bool:
	return animation_player != null


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Yaw that points the body's forward (-Z) along `dir`, taking the short way round.
func _yaw_towards(dir: Vector3) -> float:
	var yaw := atan2(-dir.x, -dir.z)
	return body.rotation.y + wrapf(yaw - body.rotation.y, -PI, PI)
