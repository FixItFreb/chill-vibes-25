extends Node
class_name ZoneMap

@onready var map_area: Area3D = $MapArea
@onready var zonemap_spawner: NetEntitySpawner = $EntitySpawner

var world: ZoneMapWorld
var players_in_zone: Dictionary[int,PlayerMobile]
@export var entry_points: Array[Node3D]

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

	$DynamicEntities.child_entered_tree.connect(on_spawned_entity_added)
	$DynamicEntities.child_exiting_tree.connect(on_spawned_entity_removed)

	# Store all static entry points
	for entry_point: Node in $Map/EntryPoints.get_children():
		entry_points.append(entry_point)

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

func on_spawned_entity_removed(removed_entity: Node) -> void:
	# Is this entity a player?
	if removed_entity is PlayerMobile:
		var removed_player: PlayerMobile = removed_entity as PlayerMobile
		remove_player_from_zone(removed_player)
