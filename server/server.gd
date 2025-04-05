class_name Server
extends Node

@export var host_port: int = 42069

var data_node: Node
var world_manager: WorldManager
# TODO: Might want some sort of player data object here instead of the PlayerMobile?
var connected_players: Dictionary[int,PlayerData]
var server_started: bool = false
var tick_rate: float = 0.05
var tick_counter: float = 0

static var instance: Server
static var net_bridge: NetBridge

signal on_server_started()
signal on_server_tick()

func _process(delta: float) -> void:
	if server_started:
		tick_counter += delta
		if tick_counter >= tick_rate:
			on_server_tick.emit()
			tick_counter = 0

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
func init_player(player_spawn_data: Dictionary[StringName,Variant]) -> void:
	var player_data: PlayerData = PlayerData.new()
	player_data.player_id = player_spawn_data.get(&"player_id", -1)
	player_data.player_name = player_spawn_data.get(&"name", "UNKNOWN")
	player_data.name = str(player_data.player_id)
	connected_players.set(player_data.player_id, player_data)
	data_node.add_child(player_data)
	# Load player save here...
	# Hardcode for now
	var init_data: Dictionary[StringName,Variant] = {
		&"current_zonemap": &"test_map_01"
	}
	# Send response back to calling client
	net_bridge.init_player_done.rpc_id(player_data.player_id, var_to_bytes(init_data))
	# Load ZoneMap for player on the server
	var zonemap_world: ZoneMapWorld = world_manager.load_zonemap_world(init_data[&"current_zonemap"])

	var zonemap_data: Dictionary[StringName,Variant] = {
		&"zonemap_id": zonemap_world.zonemap_id
	}
	# Now tell the client to load the ZoneMap
	net_bridge.load_zonemap_on_client.rpc_id(player_data.player_id, var_to_bytes(zonemap_data))

	#Server instantiates the player mobiles
	world_manager.move_player_to_zonemap(player_data, zonemap_world.zonemap_id, &"Default")
	#print("world ready: %s" % [zonemap.is_node_ready()])

# Remove the player data node from the server
func remove_player(player_id: int) -> void:
	var player_data_node: PlayerData = data_node.get_node(str(player_id)) as PlayerData
	if player_data_node:
		player_data_node.queue_free()

static func has_player_data(player_id: int) -> bool:
	return instance.connected_players.has(player_id)
