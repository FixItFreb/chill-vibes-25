extends Node
class_name NetBridge

const RESPONSE_DONE = 1
const RESPONSE_ZONEMAP_LOADED = 2
const RESPONSE_PLAYER_MOVED = 3

# TODO: Might be a better way of doing this. Also might be worth being a dictionary?
#signal response_from_server(response: int)
signal server_response_zonemap_loaded()
signal server_response_player_moved()

# Sent to client
@rpc("authority", "call_remote", "reliable")
func send_server_response(response: int) -> void:
	#response_from_server.emit(response)
	match response:
		RESPONSE_ZONEMAP_LOADED:
			server_response_zonemap_loaded.emit()
		RESPONSE_PLAYER_MOVED:
			server_response_player_moved.emit()

# Sent to server
@rpc("any_peer", "call_remote", "reliable")
func request_init_player(spawn_data: Dictionary) -> void:
	if multiplayer.is_server():
		spawn_data.set("sender_id", multiplayer.get_remote_sender_id())
		Server.instance.init_player(spawn_data)

# Sent to client
@rpc("authority", "call_remote", "reliable")
func init_player_done(init_data: Dictionary) -> void:
	if !multiplayer.is_server():
		Client.instance.init_player_done(init_data)


# Runs on server and local client
@rpc("any_peer", "call_local", "reliable")
func request_load_zonemap(zonemap_data: Dictionary) -> void:
	# Call to server
	if multiplayer.is_server():
		var zonemap_id: StringName = zonemap_data.get("zonemap_id", "")
		# Load the zone map
		Server.instance.world_manager.load_zonemap(zonemap_id)
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
		var zonemap_id: StringName = zonemap_data.get("zonemap_id", "")
		var zonemap: ZoneMap = Server.instance.world_manager.load_zonemap(zonemap_id)
		var zonemap_entrance: StringName = zonemap_data.get("zonemap_entrance", "")
		if Server.instance.world_manager.move_player_to_zonemap(player_data, zonemap, zonemap_entrance):
			send_server_response.rpc_id(player_data.player_id, RESPONSE_PLAYER_MOVED)
	# Waits for server response on client
	else:
		server_response_player_moved.connect(
			func():
				Debugger.log("Player Moved", self)
				Client.instance.acquire_player_control(),
			CONNECT_ONE_SHOT
		)
