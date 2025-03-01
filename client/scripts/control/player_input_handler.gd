class_name PlayerInputHandler
extends Node

@onready var player_cam: Camera3D = $CameraMount/CamArm/Camera3D
@onready var player_cam_mount: RemoteNode3D = $CameraMount

@export var face_move_direction: bool = true

var controlled: MobileLocomotion

func _process(_delta: float) -> void:
	if controlled:
		var control_input: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
		controlled.input_basis = player_cam.transform.basis
		controlled.input_dir = control_input
		controlled.sprinting = Input.is_action_pressed("sprint")
		#controlled.jumping = Input.is_action_just_pressed("jump")

func set_controlled(new_controlled: CharacterBody3D) -> void:
	controlled = new_controlled.get_node("Locomotion")
	if controlled:
		player_cam_mount.set_tracked_node(new_controlled)
