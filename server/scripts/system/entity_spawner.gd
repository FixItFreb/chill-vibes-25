extends MultiplayerSpawner
class_name EntitySpawner

func _ready() -> void:
	spawn_function = on_spawn

func spawn_player(player_data: PlayerData, spawn_point: Node3D) -> Node:
	var player_spawn_data: Dictionary = {
		"entity_type": "player_mobile",
		"mobile_config_id": "cake_cat",
		"player_id": player_data.player_id,
		"player_name": player_data.player_name,
		"player_pos": spawn_point.global_position,
		"player_rot": spawn_point.global_rotation
	}
	return spawn(player_spawn_data)

func on_spawn(data: Variant) -> Node:
	var spawned_node: Node = null
	var to_spawn: PackedScene = null
	var spawn_data: Dictionary = data as Dictionary
	match spawn_data["entity_type"]:
		"player_mobile":
			var player_id: int = spawn_data["player_id"]
			to_spawn = ResourcesDB.get_entity_scene("player_mobile")
			var player_node: PlayerMobile = to_spawn.instantiate()
			player_node.mobile_config_id = spawn_data["mobile_config_id"]
			player_node.owner_id = player_id
			#player_node.set_multiplayer_authority(player_id, false)
			#player_node.get_node("OwnerSync").set_multiplayer_authority(player_id, false)
			#player_node.get_node("RemoteSync").set_multiplayer_authority(1, false)
			player_node.name = "Player_%s" % [player_id]
			player_node.mobile_name = spawn_data["player_name"]
			player_node.position = spawn_data["player_pos"]
			player_node.rotation = spawn_data["player_rot"]
			# TODO: Load player saved data here?
			return player_node
		"base_mobile":
			to_spawn = ResourcesDB.get_entity_scene("base_mobile")
			var mobile_node: BaseMobile = to_spawn.instantiate()
			mobile_node.mobile_config_id = spawn_data["mobile_config_id"]
			return mobile_node
		"world":
			var zonemap_id: String = spawn_data["zonemap_id"]
			# TODO: Change this to instantiate from UID instead of packedscene var
			var world_node: ZoneMapWorld = Server.instance.world_manager.zonemapworld_scene.instantiate()
			world_node.zonemap_id = zonemap_id
			world_node.name = zonemap_id
			#Debugger.log("Honk!", self)
			#world_node.spawn_zonemap()
			return world_node
		"zonemap":
			var zonemap_id: StringName = spawn_data["zonemap_id"]
			var zonemap_scene: PackedScene = ResourcesDB.get_map_scene(zonemap_id)
			var zonemap_node: ZoneMap = zonemap_scene.instantiate()
			zonemap_node.name = "ZoneMap"
			zonemap_node.world = get_node(spawn_path)
			#Debugger.log("Meep!", self)
			return zonemap_node
	return spawned_node
