class_name Client
extends Node

@export var connect_to_address: String = "127.0.0.1"
@export var connect_to_port: int = 42069

@export var player_scene: PackedScene

signal zonemap_changed(new_zonemap: ZoneMap)

static var instance: Client
static var player_id: int

var data_node: Node
var world_manager: WorldManager
var net_bridge: NetBridge
var player_controls: PlayerInputHandler
var player_mobile: PlayerMobile

var prev_zonemap: ZoneMap
var current_zonemap: ZoneMap

var player_data_ready: bool = false

# Testing vars, these will come from player save data
var player_name: String = ""
var player_map: String = "test_map_01"

func _enter_tree() -> void:
	# This sets the Client node to be the root for all multiplayer calls made to this clients multiplayer interface
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())

func _ready() -> void:
	if instance == null:
		instance = self
		world_manager = $World
		data_node = $Data
		net_bridge = $NetBridge
		player_controls = $PlayerControls
		zonemap_changed.connect(join_new_zonemap)
	else:
		queue_free()

func join_with_defaults() -> void:
	join(connect_to_address, connect_to_port)

func join(address: String, port: int) -> void:
	player_data_ready = false
	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

	# Attempt to connect to given address and port
	var client_result: int = client_peer.create_client(address, port)
	match(client_result):
		OK:
			# Client connected to server, set it as the active peer
			multiplayer.multiplayer_peer = client_peer
		_:
			# Couldn't connect to server
			print("Could not connect to server: %s:%s" % [address, str(port)])
			return

	multiplayer.connected_to_server.connect(
		func():
			Debugger.log("Connected to server", self)
			# Do new game stuff here...
			player_id = multiplayer.get_unique_id()
			request_spawn_player()
	)

	multiplayer.server_disconnected.connect(
		func():
			Debugger.log("Disconnected from server", self)
	)

func request_spawn_player() -> void:
	# TODO: Make some player save resources for this
	var test_data: Dictionary = {
		"player_id": player_id,
		"player_name": player_name
	}
	net_bridge.request_init_player.rpc(test_data)

# Player data has now been initialised on the server
# TODO: Move camera out to a safe place before we zone
func init_player_done(_init_data: Dictionary) -> void:
	player_data_ready = true
	var zonemap_data: Dictionary = {
		"zonemap_id": player_map
	}
	net_bridge.request_load_zonemap.rpc(zonemap_data)

# Fires when a new ZoneMap runs its ready function
func join_new_zonemap(new_zonemap: ZoneMap) -> void:
	Debugger.log("Joining ZoneMap: %s" % [new_zonemap.name], self)
	current_zonemap = new_zonemap
	# TODO: Hook up player controls here
	# var join_data: Dictionary = {
	# 	"zonemap_id": new_zonemap.name,
	# }
	# net_bridge.request_move_to_zonemap.rpc(join_data)

func acquire_player_control() -> void:
	player_mobile = current_zonemap.get_node("DynamicEntities/Player_%s" % [player_id])
	player_controls.set_controlled(player_mobile)
	player_controls.player_cam_mount.reparent(current_zonemap)
