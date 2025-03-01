extends Resource
class_name MobileConfig

@export var mesh_scene_id: StringName
@export var anim_library_id: StringName
@export var collision_profile_id: StringName

# TODO: Make a stats config

# Instantiates and returns the configs mesh scene if set
func instantiate_mesh(mobile_node: Node3D) -> void:
	if mesh_scene_id.length() > 0:
		var mesh_res: PackedScene = ResourcesDB.get_mesh_resource(mesh_scene_id)
		if mesh_res:
			var mesh_node: Node = mesh_res.instantiate()
			mesh_node.name = "mesh"
			mobile_node.add_child(mesh_node)

# Applies collision shape and offsets
func apply_collision_shape(collision: CollisionShape3D) -> void:
	if collision_profile_id.length() > 0:
		var profile_res: CollisionProfile = ResourcesDB.get_collision_profile(collision_profile_id)
		if profile_res:
			collision.shape = profile_res.collision_shape
			collision.position = profile_res.collision_offset_pos
			collision.rotation = profile_res.collision_offset_rot

# Iterates through anims in the config anim library and adds them to the mobiles global anim library
func add_anims(anim_player: AnimationPlayer) -> void:
	if anim_library_id.length() > 0:
		var anim_library: AnimationLibrary = ResourcesDB.get_anims_library(anim_library_id)
		if anim_library:
			var mobile_anims: AnimationLibrary = anim_player.get_animation_library("")
			#Debugger.log("Anim count: %s" % [mobile_anims.get_animation_list_size()], anim_player)
			for anim_name: StringName in anim_library.get_animation_list():
				mobile_anims.add_animation(anim_name, anim_library.get_animation(anim_name))
