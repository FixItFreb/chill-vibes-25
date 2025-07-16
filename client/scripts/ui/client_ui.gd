extends CanvasLayer
class_name ClientUI

static var instance: ClientUI

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_debug"):
		DebugUI.ToggleUI()

