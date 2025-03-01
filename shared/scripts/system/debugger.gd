extends Node
class_name Debugger

static func log(log_text: String, log_node: Node) -> void:
	if log_node.multiplayer.is_server():
		print("%s : Server : %s" % [Time.get_time_string_from_system(), log_text])
	else:
		print("%s : Client[%s] : %s" % [Time.get_time_string_from_system(), log_node.multiplayer.get_unique_id(), log_text])
