extends Area3D
class_name ZoneMapWarp

# This is the ZoneMap ID for the zone we want to visit
@export var destination_zonemap: StringName
@export var destination_entry_id: StringName

func _ready() -> void:
	var zonemap_node: ZoneMap = find_parent("ZoneMap")
	if zonemap_node:
		for entry_point: Node in $EntryPoints.get_children():
			zonemap_node.entry_points.append(entry_point)

	body_entered.connect(on_body_entered)

func on_body_entered(entered: Node3D) -> void:
	if entered is PlayerMobile:
		var player: PlayerMobile = entered as PlayerMobile
		if player.is_owner():
			var zonemap_data: Dictionary = {
				"zonemap_id": destination_zonemap,
				"zonemap_entry_id": destination_entry_id
			}
			Client.instance.net_bridge.request_load_zonemap.rpc(zonemap_data)
		Debugger.log("Sending %s to %s : %s" % [player.mobile_name, destination_zonemap, destination_entry_id], self)
			