extends Node
class_name WorldManager

@onready var world_spawner: EntitySpawner = $WorldSpawner
@export var zonemap_scene: PackedScene

# TODO: Make sure the client waits for server loading
# TODO: Probably replace this with a MultiplayerSpawner
@rpc("any_peer", "call_remote", "reliable")
func open_zonemap(map_path: String) -> ZoneMap:
	var sender_id: int = multiplayer.get_remote_sender_id()
	# Execute if we are the server OR the calling client
	if multiplayer.is_server() or sender_id == multiplayer.get_unique_id() or sender_id == 0:
		var map_uid: String = str(ResourceLoader.get_resource_uid(map_path))
		# Check to see if this map is already loaded
		var zonemap: ZoneMap = find_child(map_uid)
		if zonemap == null:
			var map: Node = (load(map_path) as PackedScene).instantiate()
			map.name = (map.get_node("Data") as MapData).map_name
			zonemap = zonemap_scene.instantiate() as ZoneMap
			zonemap.name = map_uid
			zonemap.add_child(map)
			zonemap.ready.connect(
				func on_zonemap_ready():
					# This is where we need to reparent the player character
					# if multiplayer.is_server():
					# 	rpc_id(sender_id, "open_zonemap_local", map_path)
					pass
			)
			add_child(zonemap)
		return zonemap
	return null

# @rpc("any_peer", "call_remote", "reliable")
# func open_zonemap_local(map_path: String):
# 	open_zonemap(map_path)

@rpc("any_peer", "call_remote", "reliable")
func request_map(map_name: String) -> ZoneMap:
	var sender_id: int = multiplayer.get_remote_sender_id()
	# Execute if we are the server
	if multiplayer.is_server():
		#print("%s is server" % [multiplayer.get_unique_id()])
		# Check to see if this map is already loaded
		var zonemap: ZoneMap = null
		var found_map: bool = false
		for n in get_children():
			if n.name == map_name:
				found_map = true
		if !found_map:
			var world_spawn_data: Dictionary = {
				"entity_type": "map",
				"map_name": map_name,
				"sender_id": sender_id
			}
			zonemap = world_spawner.spawn(world_spawn_data)
			move_player_to_map(sender_id)
		move_player_to_map(sender_id)
		return zonemap
	#print("%s is not server" % [multiplayer.get_unique_id()])
	return null

func move_player_to_map(peer_id: int) -> void:
	# TODO: Move the requesting player to the new map
	print("Moving player: %s to new map." % [peer_id])
	pass
