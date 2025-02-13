extends Node
class_name ZoneMap

var entity_spawner: MultiplayerSpawner

func _ready() -> void:
    entity_spawner = $EntitySpawner
    entity_spawner.spawn_function = spawn_entity

func spawn_entity(data: Variant) -> void:
    var spawn_data: Dictionary = data as Dictionary
    if spawn_data["spawn_type"] == "player":
        # Spawn player here
        if spawn_data["peer_id"] != multiplayer.get_unique_id():
            if multiplayer.is_server():
                # spawn a server player
                pass
            else:
                # spawn a remote player
                pass
            pass