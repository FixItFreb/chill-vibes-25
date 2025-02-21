extends MultiplayerSpawner
class_name EntitySpawner

func _ready() -> void:
	spawn_function = on_spawn

func spawn_player() -> Node:
	var player_spawn_data: Dictionary = {
		"entity_type": "player_mobile",
		"mobile_config_id": "cake_cat"
	}
	return spawn(player_spawn_data)

func on_spawn(data: Variant) -> Node:
	var spawned_node: Node = null
	var to_spawn: PackedScene = null
	var spawn_data: Dictionary = data as Dictionary
	match spawn_data["entity_type"]:
		"player_mobile":
			to_spawn = ResourcesDB.get_entity_scene("player_mobile")
			var player_node: PlayerMobile = to_spawn.instantiate()
			player_node.mobile_config_id = spawn_data["mobile_config_id"]

			# TODO: Load player saved data here?
			return player_node
		"base_mobile":
			to_spawn = ResourcesDB.get_entity_scene("base_mobile")
			var mobile_node: BaseMobile = to_spawn.instantiate()
			mobile_node.mobile_config_id = spawn_data["mobile_config_id"]
			return mobile_node
		"map":
			var map_name: String = spawn_data["map_name"]
			to_spawn = ResourcesDB.get_map_scene(map_name)
			var map_node: ZoneMap = to_spawn.instantiate()
			map_node.name = map_name
			
			if spawn_data["sender_id"] == multiplayer.get_unique_id():
				print("%s: Local map" % [Time.get_datetime_string_from_system()])
			elif spawn_data["sender_id"] != multiplayer.get_unique_id():
				if multiplayer.is_server():
					print("%s: Server" % [Time.get_datetime_string_from_system()])
				else:
					print("%s: Client" % [Time.get_datetime_string_from_system()])

			return map_node
	return spawned_node
