extends Node
class_name NetBridge

enum NetResponse {
	DONE,
	ZONEMAP_LOADED,
	PLAYER_MOVED,
	PLAYER_INIT
}

enum PacketType {
	PLAYER_SYNC_POS,
	PLAYER_ANIM_SYNC,
	PLAYER_FULL_SYNC,
	DESPAWN_PLAYER,
	DESPAWN_ENTITY,
	MOVE_TO_LIMBO,
	MOVE_TO_ZONEMAP,
}

enum RepType {
	RELIABLE,
	UNRELIABLE
}

# TODO: Might be a better way of doing this. Also might be worth being a dictionary?
#signal response_from_server(response: int)
signal server_response_zonemap_loaded()
signal server_response_player_moved()

signal client_response_moved_to_limbo(data: Dictionary[StringName,Variant])

# Sent from server to client
@rpc("authority", "call_remote", "reliable")
func send_server_response(response: int) -> void:
	if not multiplayer.is_server():
		match response:
			NetResponse.ZONEMAP_LOADED:
				server_response_zonemap_loaded.emit()
			NetResponse.PLAYER_MOVED:
				server_response_player_moved.emit()

# Sent from client to server
@rpc("any_peer", "call_remote", "reliable")
func request_init_player(bytes: PackedByteArray) -> void:
	if multiplayer.is_server():
		var connecting_player_id: int = multiplayer.get_remote_sender_id()
		if not Server.has_player_data(connecting_player_id):
			var spawn_data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
			Server.instance.init_player(spawn_data)
		else:
			Debugger.log("Player %s already initialised" % [connecting_player_id], self)

# Sent from server to client
@rpc("authority", "call_remote", "reliable")
func init_player_done(bytes: PackedByteArray) -> void:
	# Only clients need to receive server responses
	if not multiplayer.is_server():
		var init_data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		Client.instance.init_player_done(init_data)

# Sent from server to client
@rpc("any_peer", "call_remote", "reliable")
func load_zonemap_on_client(bytes: PackedByteArray) -> void:
	if not multiplayer.is_server():
		var zonemap_data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		var zonemap_id: StringName = zonemap_data.get(&"zonemap_id")
		Client.instance.world_manager.load_zonemap_world(zonemap_id)
		if Client.instance.player_mobile != null:
			Client.instance.acquire_player_control()

# Runs on server and local client
@rpc("any_peer", "call_local", "reliable")
func request_load_zonemap(zonemap_data: Dictionary) -> void:
	# Call to server
	if multiplayer.is_server():
		var zonemap_id: StringName = zonemap_data.get(&"zonemap_id", "")
		# Load the zone map
		Server.instance.world_manager.load_zonemap_world(zonemap_id)
		send_server_response.rpc_id(multiplayer.get_remote_sender_id(), NetResponse.ZONEMAP_LOADED)
	# Waits for server response on client
	else:
		server_response_zonemap_loaded.connect(
			func():
				Debugger.log("ZoneMap Loaded", self)
				request_move_to_zonemap.rpc(zonemap_data),
			CONNECT_ONE_SHOT
		)

# Runs on server and local client
@rpc("any_peer", "call_local", "reliable")
func request_move_to_zonemap(zonemap_data: Dictionary) -> void:
	# Call to server
	if multiplayer.is_server():
		var player_data: PlayerData = Server.instance.connected_players.get(multiplayer.get_remote_sender_id(), null)
		var zonemap_id: StringName = zonemap_data.get(&"zonemap_id", "")
		var zonemap_entrance: StringName = zonemap_data.get(&"zonemap_entry_id", &"Default")
		if Server.instance.world_manager.move_player_to_zonemap(player_data, zonemap_id, zonemap_entrance):
			send_server_response.rpc_id(player_data.player_id, NetResponse.PLAYER_MOVED)
	# Waits for server response on client
	else:
		server_response_player_moved.connect(
			func():
				Debugger.log("Player Moved", self),
			CONNECT_ONE_SHOT
		)

# Sent from client, runs on server
@rpc("any_peer", "call_remote", "unreliable")
func send_client_to_server_unreliable(packet_type: int, bytes: PackedByteArray) -> void:
	if multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		data.set(&"rep_type", RepType.UNRELIABLE)
		match packet_type:
			PacketType.PLAYER_SYNC_POS:
				var node_path: NodePath = data.get(&"node_path")
				# Check to make sure our node exists
				# When a player is moved to a new map this may not be accurate
				if Server.instance.has_node(node_path):
					var player_node: PlayerMobile = Server.instance.get_node(node_path)
					player_node.update_position(data)
					# Send to players in same zone map
					player_node.net_entity.current_zonemap.add_pending_player_sync_update(multiplayer.get_remote_sender_id(), packet_type, data)
			PacketType.PLAYER_ANIM_SYNC:
				var node_path: NodePath = data.get(&"node_path")
				# Check to make sure our node exists
				# When a player is moved to a new map this may not be accurate
				if Server.instance.has_node(node_path):
					var player_node: PlayerMobile = Server.instance.get_node(data.get(&"node_path"))
					player_node.current_anim_id = data.get(&"current_anim")
					# Send to players in same zone map
					player_node.net_entity.current_zonemap.add_pending_player_sync_update(multiplayer.get_remote_sender_id(), packet_type, data)
				
# Sent from server, runs on client
@rpc("authority", "call_remote", "unreliable")
func send_server_to_client_unreliable(packet_type: int, bytes: PackedByteArray) -> void:
	if !multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		data.set(&"rep_type", RepType.UNRELIABLE)
		match packet_type:
			PacketType.PLAYER_SYNC_POS:
				var node_path: NodePath = data.get(&"node_path")
				if Client.instance.has_node(node_path):
					var player_node: PlayerMobile = Client.instance.get_node(node_path)
					player_node.update_position(data)
			PacketType.PLAYER_ANIM_SYNC:
				var node_path: NodePath = data.get(&"node_path")
				if Client.instance.has_node(node_path):
					var player_node: PlayerMobile = Client.instance.get_node(data.get(&"node_path"))
					player_node.update_anim(data)

# Sent from client, runs on server
@rpc("any_peer", "call_remote", "reliable")
func send_client_to_server_reliable(packet_type: int, bytes: PackedByteArray) -> void:
	if multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		data.set(&"rep_type", RepType.RELIABLE)
		match packet_type:
			PacketType.DESPAWN_PLAYER:
				var node_path: NodePath = data.get(&"node_path")
				# Check to make sure our node exists
				if Server.instance.has_node(node_path):
					var despawn_player: PlayerMobile = Server.instance.get_node(node_path)
					despawn_player.current_zonemap.add_pending_player_sync_update(multiplayer.get_remote_sender_id(), packet_type, data)
					# We should only ever remove a player from the server if they are logging out
					var is_logout: bool = data.get(&"is_logout")
					if is_logout:
						despawn_player.queue_free()
			PacketType.PLAYER_FULL_SYNC:
				var node_path: NodePath = data.get(&"node_path")
				if Client.instance.has_node(node_path):
					var player_node: PlayerMobile = Client.instance.get_node(data.get(&"node_path"))
					player_node.update_position(data)
					player_node.update_anim(data)
				else:
					#We need to spawn the player
					pass
			PacketType.MOVE_TO_LIMBO:
				client_response_moved_to_limbo.emit(data)


# Sent from server, runs on client
@rpc("authority", "call_remote", "reliable")
func send_server_to_client_reliable(packet_type: int, bytes: PackedByteArray) -> void:
	if !multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		data.set(&"rep_type", RepType.RELIABLE)
		match packet_type:
			PacketType.DESPAWN_PLAYER:
				var node_path: NodePath = data.get(&"node_path")
				# Check to make sure our node exists
				if Client.instance.has_node(node_path):
					var despawn_player: PlayerMobile = Client.instance.get_node(node_path)
					despawn_player.queue_free()
			PacketType.MOVE_TO_LIMBO:
				var node_path: NodePath = data.get(&"node_path")
				# Check to make sure our node exists
				if Client.instance.has_node(node_path):
					var player_node: PlayerMobile = Client.instance.get_node(node_path)
					if player_node.is_owner():
						pass
			PacketType.MOVE_TO_ZONEMAP:
				var node_path: NodePath = data.get(&"node_path")
				Debugger.log("Meep: %s" % node_path, self)
				# Check to make sure our node exists
				var player_node: PlayerMobile = Client.instance.player_mobile
				if player_node.is_owner():
					var zonemap: ZoneMap = Client.instance.world_manager.get_zonemap(data.get(&"zonemap_id"))
					var new_pos: Vector3 = data.get(&"position")
					var new_rot: Vector3 = data.get(&"rotation")
					if zonemap:
						var prev_zonemap: ZoneMap = player_node.net_entity.current_zonemap
						player_node.net_entity.current_zonemap = zonemap
						player_node.reparent(zonemap.entities_root)
						player_node.global_position = new_pos
						player_node.global_rotation = new_rot
						player_node.refresh_zonemap()
						if prev_zonemap:
							prev_zonemap.world.queue_free()
					else:
						Debugger.log("No valid zonemap found to move player to.", self)
