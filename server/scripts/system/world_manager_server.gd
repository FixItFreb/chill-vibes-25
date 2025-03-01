extends Node
class_name WorldManager

@onready var world_spawner: EntitySpawner = $WorldSpawner
@export var zonemap_scene: PackedScene

func load_zonemap(zonemap_id: String) -> ZoneMap:
	# Execute if we are the server
	if multiplayer.is_server() && zonemap_id.length() > 0:
		#print("%s is server" % [multiplayer.get_unique_id()])
		# Check to see if this map is already loaded
		var zonemap: ZoneMap = null
		var found_map: bool = false
		for n in get_children():
			if n.name == zonemap_id:
				found_map = true
				zonemap = n
		if !found_map:
			var world_spawn_data: Dictionary = {
				"entity_type": "map",
				"map_name": zonemap_id
			}
			zonemap = world_spawner.spawn(world_spawn_data)
		return zonemap
	#print("%s is not server" % [multiplayer.get_unique_id()])
	return null

func move_player_to_zonemap(player_data: PlayerData, zonemap: ZoneMap, _zonemap_entrance: StringName) -> bool:
	# TODO: Add removing player from current zonemap. Probably need to detach all synchronizers _before_ freeing/moving player.
	if player_data:
		# Is this a new zone or just an in zone teleport?
		var new_zone: bool = player_data.current_zonemap_id != zonemap.name
		# If it is a new zone update our current zone data
		if new_zone:
			player_data.current_zonemap_id = zonemap.name
			var player_mobile: PlayerMobile = zonemap.entity_spawner.spawn_player(player_data)
			player_mobile.owner_sync.set_visibility_for(player_data.player_id, true)
			player_data.player_mobile = player_mobile
			# TODO: Move player mobile to the specified entrance point
			return true
	return false

func remove_player_from_zonemap(player_data: PlayerData, zonemap: ZoneMap) -> bool:
	return true
