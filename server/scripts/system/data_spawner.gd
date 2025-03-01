extends MultiplayerSpawner
class_name DataSpawner

func _ready() -> void:
	spawn_function = on_spawn

func on_spawn(data: Variant) -> Node:
	var spawned_node: Node = null
	var spawn_data: Dictionary = data as Dictionary
	var data_type: String = spawn_data.get("data_type", "") as String
	if data_type.length() > 0:
		match data_type:
			"player_data":
				var player_data_node: PlayerData = PlayerData.new()
				player_data_node.player_id = spawn_data.get("player_id", -1)
				player_data_node.player_mobile = spawn_data.get("player_mobile", null)
				spawned_node = player_data_node
	return spawned_node
