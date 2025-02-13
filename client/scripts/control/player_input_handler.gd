class_name PlayerInputHandler
extends Node

@onready var player_cam: Camera3D = $CamArm/Camera3D
@onready var player_cam_arm: RemoteNode3D = $CamArm

var controlled: MobileLocomotion

func _process(_delta: float) -> void:
	if controlled:
		controlled.input_dir = Input.get_vector("left", "right", "forwards", "backwards")
		controlled.sprinting = Input.is_action_pressed("sprint")
		#controlled.jumping = Input.is_action_just_pressed("jump")

func set_controlled(new_controlled: CharacterBody3D) -> void:
	controlled = new_controlled.get_node("Locomotion")
	if controlled:
		player_cam_arm.set_tracked_node(new_controlled)
