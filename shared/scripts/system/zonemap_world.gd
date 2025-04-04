extends SubViewport
class_name ZoneMapWorld

# TODO: ZoneMap Worlds need to use Network Synchronizers to manage players that are able to see the maps and prevent multiple maps loading on a client
@export var zonemap_id: StringName
var zonemap_node: ZoneMap

func _init() -> void:
	audio_listener_enable_3d = true
	own_world_3d = true
	world_3d = World3D.new()

func _ready() -> void:
	var zonemap_scene: PackedScene = ResourcesDB.get_map_scene(zonemap_id)
	zonemap_node = zonemap_scene.instantiate()
	zonemap_node.name = "ZoneMap"
	zonemap_node.world = self
	add_child(zonemap_node)
	Debugger.log("Spawning ZoneMap: %s" % [zonemap_id], self)

func spawn(spawn_data: Dictionary[StringName,Variant]) -> Variant:
	return zonemap_node.zonemap_spawner.spawn_entity_on_server(spawn_data)