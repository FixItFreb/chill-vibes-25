extends Node
class_name NetBridge

enum NetResponse {
	DONE,
	ZONEMAP_LOADED,
	PLAYER_MOVED,
	PLAYER_INIT
}

enum DataType {
	PLAYER_SYNC_POS,
	PLAYER_ANIM_SYNC,
	PLAYER_FULL_SYNC,
}

const RESPONSE_DONE = 1
const RESPONSE_ZONEMAP_LOADED = 2
const RESPONSE_PLAYER_MOVED = 3
const RESPONSE_PLAYER_INIT = 4

# TODO: Might be a better way of doing this. Also might be worth being a dictionary?
#signal response_from_server(response: int)
signal server_response_zonemap_loaded()
signal server_response_player_moved()

# Sent from server to client
@rpc("authority", "call_remote", "reliable")
func send_server_response(response: int) -> void:
	if not multiplayer.is_server():
		match response:
			RESPONSE_ZONEMAP_LOADED:
				server_response_zonemap_loaded.emit()
			RESPONSE_PLAYER_MOVED:
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

# Runs on server and local client
@rpc("any_peer", "call_local", "reliable")
func request_load_zonemap(zonemap_data: Dictionary) -> void:
	# Call to server
	if multiplayer.is_server():
		var zonemap_id: StringName = zonemap_data.get(&"zonemap_id", "")
		# Load the zone map
		Server.instance.world_manager.load_zonemap_world(zonemap_id)
		send_server_response.rpc_id(multiplayer.get_remote_sender_id(), RESPONSE_ZONEMAP_LOADED)
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
			send_server_response.rpc_id(player_data.player_id, RESPONSE_PLAYER_MOVED)
	# Waits for server response on client
	else:
		server_response_player_moved.connect(
			func():
				Debugger.log("Player Moved", self),
			CONNECT_ONE_SHOT
		)

# Sent from client, runs on server
@rpc("any_peer", "call_remote", "unreliable")
func send_client_to_server_unreliable(data_type: int, bytes: PackedByteArray) -> void:
	if multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		match data_type:
			DataType.PLAYER_SYNC_POS:
				var player_node: PlayerMobile = Server.instance.get_node(data.get(&"node_path"))
				player_node.update_position(data)
				# Send to players in same zone map
				player_node.net_entity.current_zonemap.add_pending_player_sync_update(multiplayer.get_remote_sender_id(), data_type, data)
			DataType.PLAYER_ANIM_SYNC:
				var player_node: PlayerMobile = Server.instance.get_node(data.get(&"node_path"))
				player_node.current_anim_id = data.get(&"current_anim")
				# Send to players in same zone map
				player_node.net_entity.current_zonemap.add_pending_player_sync_update(multiplayer.get_remote_sender_id(), data_type, data)
				

# Sent from server, runs on client
@rpc("authority", "call_remote", "reliable")
func send_server_to_client_unreliable(data_type: int, bytes: PackedByteArray) -> void:
	if !multiplayer.is_server():
		var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
		match data_type:
			DataType.PLAYER_SYNC_POS:
				var player_node: PlayerMobile = Client.instance.get_node(data.get(&"node_path"))
				player_node.update_position(data)
			DataType.PLAYER_ANIM_SYNC:
				var player_node: PlayerMobile = Client.instance.get_node(data.get(&"node_path"))
				player_node.update_anim(data)
			DataType.PLAYER_FULL_SYNC:
				var player_node: PlayerMobile = Client.instance.get_node(data.get(&"node_path"))
				player_node.update_position(data)
				player_node.update_anim(data)
