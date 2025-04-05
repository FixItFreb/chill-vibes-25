extends Node
class_name ZoneMap

@onready var map_area: Area3D = $MapArea
@onready var zonemap_spawner: NetEntitySpawner = $EntitySpawner

var world: ZoneMapWorld
var players_in_zone: Dictionary[int,PlayerMobile]
@export var entry_points: Array[Node3D]

var pending_player_sync_updates: Dictionary[int,Dictionary]

var zonemap_id: StringName:
	get:
		return world.name

signal on_player_join(player: PlayerMobile)
signal on_player_leave(player: PlayerMobile)

func _ready() -> void:
	# This is a new zonemap on a client
	# This signal will move our camera to it
	if !multiplayer.is_server():
		Client.instance.zonemap_changed.emit(self)

	if multiplayer.is_server():
		Server.instance.on_server_tick.connect(process_pending_player_sync_updates)

	$DynamicEntities.child_entered_tree.connect(on_spawned_entity_added)
	$DynamicEntities.child_exiting_tree.connect(on_spawned_entity_removed)

	# Store all static entry points
	for entry_point: Node in $Map/EntryPoints.get_children():
		entry_points.append(entry_point)

	# TODO: If server, connect to on_server_tick to handle any incoming updates

func _exit_tree() -> void:
	# If we are a client, then the player camera is a child of this node so let's move it back out
	if !multiplayer.is_server():
		Client.instance.player_controls.recover_cam()

func get_entry_point(entry_point_id: StringName) -> Node3D:
	for entry_point: Node3D in entry_points:
		if entry_point.name == entry_point_id:
			return entry_point
	return entry_points[0]

func add_player_to_zone(to_add: PlayerMobile) -> bool:
	if not players_in_zone.has(to_add.owner_id):
		players_in_zone.set(to_add.owner_id, to_add)
		on_player_join.emit(to_add)
		Debugger.log("Player %s entered %s" % [to_add.mobile_name, world.name], self)

		# TODO: Shift this on to the NetEntity node...
		# If this is the server, sync all existing players
		if multiplayer.is_server():
			for player: PlayerMobile in players_in_zone.values():
				if player.owner_id != to_add.owner_id:
					zonemap_spawner.spawn_entity_on_client.rpc_id(to_add.owner_id, var_to_bytes(player.get_current_data()))

		return true
	return false

func remove_player_from_zone(to_remove: PlayerMobile) -> bool:
	if players_in_zone.has(to_remove.owner_id):
		players_in_zone.erase(to_remove.owner_id)
		on_player_leave.emit(to_remove)
		Debugger.log("Player %s left %s" % [to_remove.mobile_name, world.name], self)
		return true
	return false

func on_spawned_entity_added(new_entity: Node) -> void:
	# Is this new entity a player?
	if new_entity is PlayerMobile:
		var new_player: PlayerMobile = new_entity as PlayerMobile
		add_player_to_zone(new_player)
		push_current_player_data(new_player.owner_id)

func on_spawned_entity_removed(removed_entity: Node) -> void:
	# Is this entity a player?
	if removed_entity is PlayerMobile:
		var removed_player: PlayerMobile = removed_entity as PlayerMobile
		remove_player_from_zone(removed_player)

func push_current_player_data(new_player_id: int) -> void:
	if multiplayer.is_server():
		# Iterate across all players in this zone
		for existing_player_id: int in players_in_zone:
			if existing_player_id != new_player_id:
				var player_node: PlayerMobile = players_in_zone.get(existing_player_id)
				Server.net_bridge.send_server_to_client_unreliable.rpc_id(new_player_id, NetBridge.DataType.PLAYER_FULL_SYNC, var_to_bytes(player_node.get_current_data()))

func add_pending_player_sync_update(player_id: int, sync_type: int, update_data: Dictionary[StringName,Variant]) -> void:
	#pending_player_sync_updates.set(player_id, update_data)
	if not pending_player_sync_updates.has(player_id):
		var new_sync_data_entry: Dictionary[int,Dictionary] = {
			sync_type: update_data
		}
		pending_player_sync_updates.set(player_id, new_sync_data_entry)
	else:
		var sync_data_entry: Dictionary[int,Dictionary] = pending_player_sync_updates.get(player_id)
		sync_data_entry.set(sync_type, update_data)

# Iterate across all our pending updates and send those updates to other players in the zone
func process_pending_player_sync_updates() -> void:
	if multiplayer.is_server():
		# Iterate across all our pending updates
		for sending_player_id: int in pending_player_sync_updates.keys():
			# Iterate across all players in this zone
			for receiving_player_id: int in players_in_zone:
				# Only process updates this player is not the owner of the update data
				if receiving_player_id != sending_player_id:
					var sync_data: Dictionary[int,Dictionary] = pending_player_sync_updates.get(sending_player_id)
					for sync_entry_type: int in sync_data.keys():
						Server.net_bridge.send_server_to_client_unreliable.rpc_id(receiving_player_id, sync_entry_type, var_to_bytes(sync_data.get(sync_entry_type)))
		pending_player_sync_updates.clear()


	
