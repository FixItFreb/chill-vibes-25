extends Node
class_name WorldManager

const ZONEMAP_CHILD_INDEX: int = 2

@onready var world_spawner: EntitySpawner = $WorldSpawner
@export var zonemap_scene: PackedScene
@export var zonemapworld_scene: PackedScene

func load_zonemap_world(zonemap_id: StringName) -> ZoneMapWorld:
	#if multiplayer.is_server() && zonemap_id.length() > 0:
	if zonemap_id.length() > 0:
		var zonemap_world: ZoneMapWorld = null
		var found_world: bool = false
		for n in get_children():
			if n.name == zonemap_id:
				Debugger.log("Using existing zonemap world for: %s" % [zonemap_id], self)
				found_world = true
				zonemap_world = n
				break
		if !found_world:
			Debugger.log("Setting up new zonemap world: %s" % [zonemap_id], self)
			zonemap_world = ZoneMapWorld.new()
			zonemap_world.zonemap_id = zonemap_id
			zonemap_world.name = zonemap_id
			add_child(zonemap_world)
		return zonemap_world
	return null

func get_zonemap(zonemap_id: StringName) -> ZoneMap:
	for n in get_children():
		# If the name matches the zonemap ID this is our world node
		if n.name == zonemap_id:
			return n.get_node("ZoneMap")
	# TODO: Might want to return a default zonemap here?
	return null

# TODO: Run this _before_ we load a ZoneMap and have this load the ZoneMap if needed
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
			#zonemap.world.add_player_to_world(player_data.player_id)

			player_data.current_zonemap = zonemap
			Debugger.log("Player %s entering %s at %s" % [player_data.player_id, zonemap.zonemap_id, zonemap_entry_id], self)
			#var player_mobile: PlayerMobile = zonemap.entity_spawner.spawn_player(player_data, zonemap.get_entry_point(zonemap_entry_id))

			var spawn_point: Node3D = zonemap.get_entry_point(zonemap_entry_id)
			var player_spawn_data: Dictionary[StringName,Variant] = {
				&"entity_type": NetEntity.EntityType.PLAYER_MOBILE,
				&"mobile_config_id": &"cake_cat",
				&"player_id": player_data.player_id,
				&"name": player_data.player_name,
				&"position": spawn_point.global_position,
				&"rotation": spawn_point.global_rotation
			}
			var player_mobile: PlayerMobile = zonemap.zonemap_spawner.spawn_entity(player_spawn_data)

			player_data.player_mobile = player_mobile
			# TODO: Move player mobile to the specified entrance point
			return true
	return false

func remove_player_from_zonemap(player_data: PlayerData, zonemap: ZoneMap) -> bool:
	return true
