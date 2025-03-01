class_name Server
extends Node

@export var host_port: int = 42069

var data_node: Node
var world_manager: WorldManager
var net_bridge: NetBridge
# TODO: Might want some sort of player data object here instead of the PlayerMobile?
var connected_players: Dictionary[int,PlayerData]
var server_started: bool = false

static var instance: Server

signal on_server_started()

func _enter_tree() -> void:
	# This sets the Server node to be the root for all multiplayer calls made to the servers multiplayer interface
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())

func _ready() -> void:
	if instance == null:
		instance = self
		world_manager = $World
		data_node = $Data
		net_bridge = $NetBridge
	else:
		queue_free()

func host_with_defaults() -> void:
	host(host_port)

func host(port: int) -> void:
	# Assign a new server peer
	var server_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	server_started = false
	
	# Attempt to open a server on the given port
	var server_result: int = server_peer.create_server(port)
	match(server_result):
		OK:
			# Server started, set up the server peer
			multiplayer.multiplayer_peer = server_peer
			server_started = true
			on_server_started.emit()
		_:
			# Server failed to start, free up this server node
			get_parent().queue_free()
			return

	multiplayer.peer_connected.connect(
		func(peer_id: int):
			Debugger.log("Client connected: %s" % [str(peer_id)], self)
	)

	multiplayer.peer_disconnected.connect(
		func(peer_id: int):
			Debugger.log("Client disconnected: %s" % [str(peer_id)], self)
			remove_player(peer_id)
	)

# Add player data to the server
func init_player(player_spawn_data: Dictionary) -> void:
	var player_data: PlayerData = PlayerData.new()
	player_data.player_id = player_spawn_data.get("player_id", -1)
	player_data.player_name = player_spawn_data.get("player_name", "UNKNOWN")
	player_data.name = str(player_data.player_id)
	connected_players.set(player_data.player_id, player_data)
	data_node.add_child(player_data)
	var init_data: Dictionary = {}
	net_bridge.init_player_done.rpc_id(player_data.player_id, init_data)

# Remove the player data node from the server
func remove_player(player_id: int) -> void:
	var player_data_node: PlayerData = data_node.get_node(str(player_id)) as PlayerData
	if player_data_node:
		player_data_node.queue_free()

# func move_player_to_zonemap(player_data: PlayerData, zonemap: ZoneMap, _zonemap_entrance: StringName) -> bool:
# 	if player_data:
# 		# Is this a new zone or just an in zone teleport?
# 		var new_zone: bool = player_data.current_zonemap_id != zonemap.name
# 		# If it is a new zone update our current zone data
# 		if new_zone:
# 			player_data.current_zonemap_id = zonemap.name
# 			player_data.player_mobile = zonemap.entity_spawner.spawn_player()
# 			# TODO: Move player mobile to the specified entrance point
# 	return false
