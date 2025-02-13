extends Node

@export var zonemap_scene: PackedScene

func open_zonemap(map_path: String) -> void:
    var map: Node = (load(map_path) as PackedScene).instantiate()
    map.name = (map.get_node("Data") as MapData).map_name
    var zonemap: Node = zonemap_scene.instantiate()
    zonemap.add_child(map)
    add_child(zonemap)
