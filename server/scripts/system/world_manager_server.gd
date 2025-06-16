extends Node
class_name WorldManager

const ZONEMAP_CHILD_INDEX: int = 2

@onready var world_spawner: EntitySpawner = $WorldSpawner
@onready var limbo_world: Node = $Limbo
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
			# TODO: Technically this can fail if the world returns null
			var zonemap: ZoneMap = Server.instance.world_manager.load_zonemap_world(zonemap_id).zonemap_node
	
			# # Remove player from existing zone if we have one
			# if player_data.current_zonemap != null:
			# 	player_data.current_zonemap.world.remove_player_from_world(player_data.player_id)

			# Update current zonemap
			player_data.current_zonemap = zonemap

			Debugger.log("Player %s entering %s at %s" % [player_data.player_id, zonemap.zonemap_id, zonemap_entry_id], self)

			var spawn_point: Node3D = zonemap.get_entry_point(zonemap_entry_id)
			if player_data.player_mobile == null:
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
			else:
				player_data.player_mobile.net_entity.current_zonemap = zonemap
				player_data.player_mobile.reparent(zonemap.entities_root)
				player_data.player_mobile.global_position = spawn_point.global_position
				player_data.player_mobile.global_rotation = spawn_point.global_rotation

				var move_data: Dictionary[StringName,Variant] = {
			 		&"node_path": Server.instance.get_path_to(player_data.player_mobile),
					&"zonemap_id": zonemap_id,
					&"position": spawn_point.global_position,
					&"rotation": spawn_point.global_rotation
				}
				Server.net_bridge.send_server_to_client_reliable.rpc_id(player_data.player_id, NetBridge.PacketType.MOVE_TO_ZONEMAP, var_to_bytes(move_data))
			return true
		else:
			# Teleports player within the current zone
			var spawn_point: Node3D = player_data.current_zonemap.get_entry_point(zonemap_entry_id)
			player_data.player_mobile.global_position = spawn_point.global_position
			player_data.player_mobile.global_rotation = spawn_point.global_rotation
			Debugger.log("Teleported player %s to %s" % [player_data.player_id, zonemap_entry_id], self)

			var move_data: Dictionary[StringName,Variant] = {
				&"node_path": Server.instance.get_path_to(player_data.player_mobile),
				&"zonemap_id": zonemap_id,
				&"position": spawn_point.global_position,
				&"rotation": spawn_point.global_rotation
			}
			Server.net_bridge.send_server_to_client_reliable.rpc_id(player_data.player_id, NetBridge.PacketType.MOVE_TO_ZONEMAP, var_to_bytes(move_data))
			return true
	Debugger.log("No available player data!", self)
	return false

func remove_player_from_zonemap(player_data: PlayerData, zonemap: ZoneMap) -> bool:
	return true
