extends CharacterBody3D
class_name BaseMobile

@onready var damageable: Damageable = $Damageable
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var owner_sync: MultiplayerSynchronizer = $OwnerSync
@onready var remote_sync: MultiplayerSynchronizer = $RemoteSync

@export var mobile_name: String = ""
@export var mobile_config_id: StringName
@export var owner_id: int

var current_zonemap: ZoneMap

func is_owner() -> bool:
	return multiplayer.get_unique_id() == owner_id

func _ready() -> void:
	#Debugger.log("%s ready!" % [mobile_name], self)
	init_mobile_config()
	current_zonemap = get_node("../..")
	if owner_id == multiplayer.get_unique_id():	
		damageable.on_damaged.connect(on_damage_received)
	#if multiplayer.is_server():
	# 	owner_sync.update_visibility(0)
	# 	remote_sync.update_visibility(0)

# TODO: This can be called when setting the mobile config var
func init_mobile_config() -> void:
	if mobile_config_id.length() > 0:
		var mobile_config: MobileConfig = ResourcesDB.get_mobile_config(mobile_config_id)
		if mobile_config:
			mobile_config.instantiate_mesh(self)
			mobile_config.apply_collision_shape($Collision)
			# FIXME: Hack for sprinting on listen client when other clients connect. Suspect shared data between server and listen client is the cause...
			if is_owner():
				mobile_config.add_anims(anim_player)

func on_damage_received(incoming: int) -> void:
	print("%s received %s damage." % [mobile_name, incoming])
