extends Node
class_name ZoneMap

@onready var entity_spawner: EntitySpawner = $EntitySpawner
@onready var map_area: Area3D = $MapArea

var players_in_zone: Array[int]

signal on_player_join(player: PlayerMobile)
signal on_player_leave(player: PlayerMobile)

func _ready() -> void:
	# This is a new zonemap on a client
	# This signal will move our camera to it
	if !multiplayer.is_server():
		Client.instance.zonemap_changed.emit(self)

	$DynamicEntities.child_entered_tree.connect(on_spawned_entity_added)
	$DynamicEntities.child_exiting_tree.connect(on_spawned_entity_removed)

func add_player_to_zone(to_add: PlayerMobile) -> bool:
	if !players_in_zone.has(to_add.owner_id):
		players_in_zone.append(to_add.owner_id)
		on_player_join.emit(to_add)
		return true
	return false

func remove_player_from_zone(to_remove: PlayerMobile) -> bool:
	if players_in_zone.has(to_remove.owner_id):
		players_in_zone.erase(to_remove.owner_id)
		on_player_leave.emit(to_remove)
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
