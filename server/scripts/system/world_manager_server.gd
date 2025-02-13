extends Node
class_name WorldManager

@export var zonemap_scene: PackedScene

# TODO: Make sure the client waits for server loading
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
