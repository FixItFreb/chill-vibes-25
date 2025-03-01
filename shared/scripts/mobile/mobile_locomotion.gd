extends Node
class_name MobileLocomotion

const JUMP_VELOCITY = 4.5

@export var move_speed: float = 5.0
@export var sprint_mod: float = 2.0
@export var face_move_direction: bool = true

var mobile_body: BaseMobile

var jumping: bool
var input_dir: Vector2
var input_basis: Basis
var sprinting: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent() is BaseMobile:
		mobile_body = get_parent()
	if !mobile_body:
		process_mode = Node.PROCESS_MODE_DISABLED
		push_error("Locomotion node does not have a valid BaseMobile parent.")

func _physics_process(delta: float) -> void:
	if mobile_body.owner_id == multiplayer.get_unique_id():
		# Add the gravity.
		if not mobile_body.is_on_floor():
			mobile_body.velocity += mobile_body.get_gravity() * delta

		# Handle jump.
		# if jumping and mobile_body.is_on_floor():
		# 	mobile_body.velocity.y = JUMP_VELOCITY
		# jumping = false

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var move_mod: float = sprint_mod if sprinting else 1.0
		var direction: Vector3
		direction = (input_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if direction:
			mobile_body.velocity.x = direction.x * move_speed * move_mod
			mobile_body.velocity.z = direction.z * move_speed * move_mod
		else:
			mobile_body.velocity.x = move_toward(mobile_body.velocity.x, 0, move_speed * move_mod)
			mobile_body.velocity.z = move_toward(mobile_body.velocity.z, 0, move_speed * move_mod)

		mobile_body.move_and_slide()
		if direction.length() > 0:
			mobile_body.look_at(mobile_body.global_position + direction)

		# TODO: This should probably be done via anim graphs?
		if mobile_body.velocity.length() > 0 && mobile_body.is_on_floor():
			if sprinting && mobile_body.anim_player.current_animation != "run":
				mobile_body.anim_player.play(&"run")
			elif !sprinting && mobile_body.anim_player.current_animation != "walk":
				mobile_body.anim_player.play(&"walk")
		elif mobile_body.anim_player.current_animation != "idle":
			mobile_body.anim_player.play(&"idle")
	# else:
	# 	# TODO: This should probably be done via anim graphs?
	# 	if mobile_body.velocity.length() > 0 && mobile_body.is_on_floor():
	# 		if sprinting && mobile_body.anim_player.current_animation != "run":
	# 			mobile_body.anim_player.play(&"run")
	# 		elif !sprinting && mobile_body.anim_player.current_animation != "walk":
	# 			mobile_body.anim_player.play(&"walk")
	# 	elif mobile_body.anim_player.current_animation != "idle":
	# 		mobile_body.anim_player.play(&"idle")
