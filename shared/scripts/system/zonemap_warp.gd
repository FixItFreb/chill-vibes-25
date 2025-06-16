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
		if multiplayer.is_server():
			var zonemap_data: Dictionary[StringName,Variant] = {
				"zonemap_id": destination_zonemap,
				"zonemap_entry_id": destination_entry_id
			}
			#Client.instance.net_bridge.request_load_zonemap.rpc(zonemap_data)
			# Order of moving zonemaps
			# 1 - Send player to limbo on the server
			# 2 - Send player to limbo on the client
			# 3 - Move player to new zonemap on the server
			# 4 - Move player to new zonemap on the client
			#player.reparent(Server.instance.world_manager.limbo_world)
			# send rpc to client to get them to move into limbo
			# var move_data: Dictionary[StringName,Variant] = {
			# 	&"node_path": Server.instance.get_path_to(player)
			# }
			#Server.net_bridge.send_server_to_client_reliable.rpc_id(player.owner_id, NetBridge.PacketType.MOVE_TO_LIMBO, var_to_bytes(move_data))
			# Wait for the client response
			# TODO: Timeout?
			# Server.net_bridge.client_response_moved_to_limbo.connect(
			# 	func(data: Dictionary[StringName,Variant]):
			# 		Server.net_bridge.load_zonemap_on_client.rpc_id(player.owner_id, var_to_bytes(zonemap_data))
			# )
			#Server.instance.world_manager.load_zonemap_world(destination_zonemap)
			#Server.net_bridge.load_zonemap_on_client.rpc_id(player.owner_id, var_to_bytes(zonemap_data))
			var player_data: PlayerData = Server.instance.connected_players[player.owner_id]
			var moved_player: bool = Server.instance.world_manager.move_player_to_zonemap(player_data, destination_zonemap, destination_entry_id)
			if !moved_player:
				Debugger.log("Failed to send %s to %s : %s" % [player.mobile_name, destination_zonemap, destination_entry_id], self)
			else:
				Debugger.log("Sent %s to %s : %s" % [player.mobile_name, destination_zonemap, destination_entry_id], self)
				Server.net_bridge.load_zonemap_on_client.rpc_id(player.owner_id, var_to_bytes(zonemap_data))

			
