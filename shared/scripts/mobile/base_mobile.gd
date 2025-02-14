extends CharacterBody3D
class_name BaseMobile

@onready var damageable: Damageable = $Damageable
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var mobile_name: String = ""
@export var mobile_config_id: StringName

func _ready() -> void:
	init_mobile_config()
	damageable.on_damaged.connect(on_damage_received)

# TODO: This can be called when setting the mobile config var
func init_mobile_config() -> void:
	if mobile_config_id.length() > 0:
		var mobile_config: MobileConfig = ResourcesDB.get_mobile_config(mobile_config_id)
		if mobile_config:
			mobile_config.instantiate_mesh(self)
			mobile_config.apply_collision_shape($Collision)
			mobile_config.add_anims(anim_player)

func on_damage_received(incoming: int) -> void:
	print("%s received %s damage." % [mobile_name, incoming])