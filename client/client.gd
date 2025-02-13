class_name Client
extends Node

@export var connect_to_address: String = "127.0.0.1"
@export var connect_to_port: int = 42069

@export var player_scene: PackedScene

static var instance: Client

var world_manager: WorldManager
var prev_zonemap: ZoneMap
var current_zonemap: ZoneMap

func _enter_tree() -> void:
	# This sets the Client node to be the root for all multiplayer calls made to this clients multiplayer interface
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())

func _ready() -> void:
	if instance == null:
		instance = self
		world_manager = $World
	else:
		queue_free()

func join_with_defaults() -> void:
	join(connect_to_address, connect_to_port)

func join(address: String, port: int) -> void:
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
			print("Connected to server")
			# Do new game stuff here...
			join_game()
	)

	multiplayer.server_disconnected.connect(
		func():
			print("Disconnected from server")
	)

# Request to join game at specific map
func join_game() -> void:
	world_manager.open_zonemap.rpc("uid://c222siboj2ed")
	# if current_zonemap != null:
	# 	var player_spawn_data: Dictionary = {
	# 		"spawn_type" : "player",
	# 		"peer_id" : multiplayer.get_unique_id()
	# 	}
	# 	current_zonemap.entity_spawner.spawn(player_spawn_data)
	# 	pass
