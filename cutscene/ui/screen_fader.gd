class_name ScreenFader
extends CanvasLayer
## Fullscreen colour overlay for fades to and from black (or any colour).

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(0, 0, 0, 0)
	add_child(_rect)


func get_alpha() -> float:
	return _rect.color.a


## Returns null for an instant fade.
func fade(to_alpha: float, duration: float, color := Color.BLACK) -> Tween:
	if _tween:
		_tween.kill()
	_rect.color = Color(color, _rect.color.a)
	if duration <= 0.0:
		set_alpha(to_alpha, color)
		return null
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", to_alpha, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tween


func set_alpha(alpha: float, color := Color.BLACK) -> void:
	if _tween:
		_tween.kill()
	_rect.color = Color(color, alpha)
