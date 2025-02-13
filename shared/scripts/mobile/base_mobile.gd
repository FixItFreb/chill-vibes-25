extends CharacterBody3D
class_name BaseMobile

@onready var damageable: Damageable = $Damageable
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var mobile_name: String = ""
@export var mobile_config: MobileConfig

func _ready() -> void:
    init_mobile_config()

# TODO: This can be called when setting the mobile config var
func init_mobile_config() -> void:
    if mobile_config:
        mobile_config.instantiate_mesh(self)
        mobile_config.add_anims(anim_player)