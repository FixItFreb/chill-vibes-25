extends Window
class_name DebugUI

static var instance: DebugUI

@onready var debug_text_output: TextEdit = %DebugTextOutput
@onready var debug_log_clear_button: Button = %ClearDebugLogButton

func _ready() -> void:
	if instance == null:
		instance = self
		debug_log_clear_button.pressed.connect(
			func() -> void:
				debug_text_output.text = ""
		)

static func ToggleUI() -> void:
	instance.title = "DEBUGMA - " + Client.instance.player_name
	instance.visible = !instance.visible
	instance.debug_text_output.scroll_vertical = (1 << 63) - 1

static func AppendDebugText(new: String) -> void:
	instance.debug_text_output.text = instance.debug_text_output.text + "\n" + new
	instance.debug_text_output.scroll_vertical = (1 << 63) - 1
