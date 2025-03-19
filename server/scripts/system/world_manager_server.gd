extends Node
class_name WorldManager

const ZONEMAP_CHILD_INDEX: int = 2

@onready var world_spawner: EntitySpawner = $WorldSpawner
@export var zonemap_scene: PackedScene
@export var zonemapworld_scene: PackedScene

func load_zonemap_world(zonemap_id: StringName) -> ZoneMapWorld:
	if multiplayer.is_server() && zonemap_id.length() > 0:
		var zonemap_world: ZoneMapWorld = null
		var found_world: bool = false
		for n in get_children():
			if n.name == zonemap_id:
				Debugger.log("Using existing zonemap world for: %s" % [zonemap_id], self)
				found_world = true
				zonemap_world = n
		if !found_world:
			Debugger.log("Setting up new zonemap world: %s" % [zonemap_id], self)
			var world_spawn_data: Dictionary = {
				"entity_type": "world",
				"zonemap_id": zonemap_id
			}
			zonemap_world = world_spawner.spawn(world_spawn_data)
		return zonemap_world
	return null

# func load_zonemap(zonemap_world: ZoneMapWorld) -> ZoneMap:
# 	# Execute if we are the server
# 	if multiplayer.is_server():
# 		var found_zonemap: bool = false
# 		var zonemap: ZoneMap = null
# 		for n in zonemap_world.get_children():
# 			if n.name == &"ZoneMap":
# 				found_zonemap = true
# 				zonemap = n
# 		if !found_zonemap:
# 			Debugger.log("Loading new zonemap: %s" % [zonemap_world.name], self)
# 			var zonemap_spawn_data: Dictionary = {
# 				"entity_type": "zonemap",
# 				"zonemap_id": zonemap_world.name
# 			}
# 			#zonemap = zonemap_world.zonemap_spawner.spawn(zonemap_spawn_data)
# 			zonemap = zonemap_world.spawn_zonemap(zonemap_spawn_data)
# 		return zonemap
# 	return null

func get_zonemap(zonemap_id: StringName) -> ZoneMap:
	for n in get_children():
		# If the name matches the zonemap ID this is our world node
		if n.name == zonemap_id:
			return n.get_node("ZoneMap")
	# TODO: Might want to return a default zonemap here?
	return null

# func load_zonemap(zonemap_id: String) -> ZoneMap:
# 	# Execute if we are the server
# 	if multiplayer.is_server() && zonemap_id.length() > 0:
# 		#print("%s is server" % [multiplayer.get_unique_id()])
# 		# Check to see if this map is already loaded
# 		var zonemap: ZoneMap = null
# 		var found_map: bool = false
# 		for n in get_children():
# 			if n.name == zonemap_id:
# 				found_map = true
# 				zonemap = n.get_child(1)
# 		if !found_map:
# 			Debugger.log("Loading new zonemap", self)
# 			var world_spawn_data: Dictionary = {
# 				"entity_type": "world",
# 				"map_name": zonemap_id
# 			}
# 			zonemap = world_spawner.spawn(world_spawn_data).get_child(1)
# 		return zonemap
# 	return null

func move_player_to_zonemap(player_data: PlayerData, zonemap_id: StringName, zonemap_entry_id: StringName) -> bool:
	# TODO: Add removing player from current zonemap. Probably need to detach all synchronizers _before_ freeing/moving player.
	if player_data:
		# Is this a new zone or just an in zone teleport?
		var new_zonemap: bool = player_data.current_zonemap == null || player_data.current_zonemap.zonemap_id != zonemap_id
		# If it is a new zone update our current zone data
		if new_zonemap:
			# Get new zonemap
			var zonemap: ZoneMap = get_zonemap(zonemap_id)
			# Remove player from existing zone if we have one
			if player_data.current_zonemap != null:
				player_data.current_zonemap.world.remove_player_from_world(player_data.player_id)
			# Add player to new zone
			zonemap.world.add_player_to_world(player_data.player_id)

			player_data.current_zonemap = zonemap
			Debugger.log("Player %s entering %s at %s" % [player_data.player_id, zonemap.zonemap_id, zonemap_entry_id], self)
			var player_mobile: PlayerMobile = zonemap.entity_spawner.spawn_player(player_data, zonemap.get_entry_point(zonemap_entry_id))
			#player_mobile.owner_sync.set_visibility_for(player_data.player_id, true)
			player_data.player_mobile = player_mobile
			# TODO: Move player mobile to the specified entrance point
			return true
	return false

func remove_player_from_zonemap(player_data: PlayerData, zonemap: ZoneMap) -> bool:
	return true
