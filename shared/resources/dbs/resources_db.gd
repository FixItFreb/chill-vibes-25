class_name ResourcesDB

const MAP_RESOURCES = "res://shared/scenes/maps/"
const ENTITY_RESOURCES = "res://shared/scenes/entities/"
const MOBILE_CONFIGS = "res://shared/resources/mobiles/"

const MESH_RESOURCES = "res://shared/scenes/mesh/"
const COLLISION_RESOURCES = "res://shared/resources/collision_profiles/"
const ANIM_RESOURCES = "res://shared/resources/anims/"

static func resource_path(res_type: StringName, res_name: String) -> String:
	match res_type:
		&"Maps":
			return MAP_RESOURCES + res_name + ".tscn"
		&"Entities":
			return ENTITY_RESOURCES + res_name + ".tscn"
		&"Mobiles":
			return MOBILE_CONFIGS + res_name + ".tres"
		&"Meshes":
			return MESH_RESOURCES + res_name + ".tscn"
		&"Collisions":
			return COLLISION_RESOURCES + res_name + ".tres"
		&"Anims":
			return ANIM_RESOURCES + res_name + ".tres"
	return ""

static func get_resource(res_type: StringName, res_name: String) -> Resource:
	var new_res: Resource = ResourceLoader.load(resource_path(res_type, res_name))
	if !new_res:
		printerr("Could not load resource %s:%s" % [res_type, res_name])
	return new_res

static func get_map_scene(map_name: String) -> PackedScene:
	return ResourceLoader.load(resource_path(&"Maps", map_name))

static func get_entity_scene(entity_name: String) -> PackedScene:
	return ResourceLoader.load(resource_path(&"Entities", entity_name))

static func get_mobile_config(config_name: String) -> MobileConfig:
	return ResourceLoader.load(resource_path(&"Mobiles", config_name))

static func get_mesh_resource(mesh_name: String) -> PackedScene:
	return ResourceLoader.load(resource_path(&"Meshes", mesh_name))

static func get_collision_profile(profile_name: String) -> CollisionProfile:
	return ResourceLoader.load(resource_path(&"Collisions", profile_name))

static func get_anims_library(anims_name: String) -> AnimationLibrary:
	return ResourceLoader.load(resource_path(&"Anims", anims_name))
