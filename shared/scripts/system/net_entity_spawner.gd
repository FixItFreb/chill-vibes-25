extends Node
class_name NetEntitySpawner

@export var spawn_path: NodePath

func spawn_entity(spawn_data: Dictionary) -> Variant:
	var to_spawn: Variant = null
	var entity_type: int = spawn_data[&"entity_type"]

	match entity_type:
		NetEntity.EntityType.PLAYER_MOBILE:
			to_spawn = spawn_player(spawn_data)
	
	# Spawn entity on server
	get_node(spawn_path).add_child(to_spawn)

	# Send spawn data to client
	if multiplayer.is_server():
		spawn_entity_on_client.rpc(var_to_bytes(spawn_data))
	return to_spawn

@rpc("any_peer", "call_remote", "reliable")
func spawn_entity_on_client(bytes: PackedByteArray) -> void:
	if not multiplayer.is_server():
		var spawn_data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		spawn_entity(spawn_data)

func spawn_player(spawn_data: Dictionary[StringName,Variant]) -> PlayerMobile:
	var player_id: int = spawn_data[&"player_id"]
	var to_spawn: PackedScene = ResourcesDB.get_entity_scene(&"player_mobile")
	var player_node: PlayerMobile = to_spawn.instantiate()

	player_node.mobile_config_id = spawn_data[&"mobile_config_id"]
	player_node.owner_id = player_id
	player_node.set_multiplayer_authority(player_id, true)
	player_node.name = "Player_%s" % [player_id]
	player_node.mobile_name = spawn_data[&"name"]
	player_node.position = spawn_data[&"position"]
	player_node.rotation = spawn_data[&"rotation"]
	return player_node
