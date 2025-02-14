extends Node3D
class_name RemoteNode3D

@export var tracked: Node3D
@export var track_position: bool = true
@export var track_rotation: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if !tracked:
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	if track_position:
		global_position = tracked.global_position
	
	if track_rotation:
		global_rotation = tracked.global_rotation

func set_tracked_node(to_track: Node3D) -> void:
	tracked = to_track
	process_mode = Node.PROCESS_MODE_INHERIT
