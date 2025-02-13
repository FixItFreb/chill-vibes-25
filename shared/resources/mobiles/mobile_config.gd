extends Resource
class_name MobileConfig

@export var mesh_scene: PackedScene
@export var anim_library: AnimationLibrary
@export var mobile_name: String

@export var mesh_scene_id: StringName
@export var anim_library_id: StringName

# TODO: Define stats here

# Instantiates and returns the configs mesh scene if set
func instantiate_mesh(mobile_node: Node3D) -> void:
	if mesh_scene:
		var mesh_node: Node = mesh_scene.instantiate()
		mesh_node.name = "mesh"
		mobile_node.add_child(mesh_node)

# Iterates through anims in the config anim library and adds them to the mobiles global anim library
func add_anims(anim_player: AnimationPlayer) -> void:
	if anim_library:
		var global_anims: AnimationLibrary = anim_player.get_animation_library("")
		for anim_name: StringName in anim_library.get_animation_list():
			global_anims.add_animation(anim_name, anim_library.get_animation(anim_name))
