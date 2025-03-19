extends SubViewport
class_name ZoneMapWorld

# TODO: ZoneMap Worlds need to use Network Synchronizers to manage players that are able to see the maps and prevent multiple maps loading on a client
@export var zonemap_id: StringName
@onready var server_sync: MultiplayerSynchronizer = $ServerSync
@onready var zonemap_spawner: MultiplayerSpawner = %ZoneMapSpawner
var zonemap_node: ZoneMap

# func _init() -> void:
# 	world_3d = World3D.new()
# 	audio_listener_enable_3d = true
# 	own_world_3d = true

func _ready() -> void:
	if multiplayer.is_server():
		if zonemap_node == null:
			Debugger.log("Loading new zonemap: %s" % [zonemap_id], self)
			var zonemap_spawn_data: Dictionary = {
				"entity_type": "zonemap",
				"zonemap_id": zonemap_id
			}
			zonemap_node = zonemap_spawner.spawn(zonemap_spawn_data)

# func _ready() -> void:
# 	# If we are the server spawn the zonemap now
# 	if multiplayer.is_server():
# 		server_sync.set_visibility_for(1, true)
# 		spawn_zonemap()
# 	# If we are a client connect to our synch signal
# 	else:
# 		if zonemap_id.length() > 0:
# 			spawn_zonemap()
# 		server_sync.synchronized.connect(on_sync)

# Spawn the current zonemap ID
# TODO: This doesn't check to see if a map is already spawned, it _shouldn't_ be a problem but just in case might be worth adding some checks
# TODO: This needs to be moved to using a MultiplayerSpawner. Dynamically spawned nodes that have synchronizers nested under them will try to transmit too early otherwise.
# func spawn_zonemap(zonemap_spawn_data: Variant) -> ZoneMap:
# 	return zonemap_spawner.spawn(zonemap_spawn_data)
# 	# var zonemap_scene: PackedScene = ResourcesDB.get_map_scene(zonemap_id)
# 	# if zonemap_scene:
# 	# 	zonemap_node = zonemap_scene.instantiate()
# 	# 	zonemap_node.name = "ZoneMap"
# 	# 	zonemap_node.world = self
# 	# 	add_child(zonemap_node)

# func on_sync() -> void:
# 	# When a client gets a new zonemap ID synced from the server, spawn the zonemap
# 	# if !multiplayer.is_server():
# 	# 	spawn_zonemap()

func add_player_to_world(player_id: int) -> void:
	server_sync.set_visibility_for(player_id, true)
	server_sync.update_visibility(player_id)
	zonemap_node.server_sync.set_visibility_for(player_id, true)
	zonemap_node.server_sync.update_visibility(player_id)

func remove_player_from_world(player_id: int) -> void:
	zonemap_node.server_sync.set_visibility_for(player_id, false)
	zonemap_node.server_sync.update_visibility(player_id)
	server_sync.set_visibility_for(player_id, false)
	server_sync.update_visibility(player_id)
