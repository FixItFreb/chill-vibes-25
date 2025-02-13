class_name Server
extends Node

@export var host_port: int = 42069

var world_manager: WorldManager

static var instance: Server

signal server_started()

func _enter_tree() -> void:
	# This sets the Server node to be the root for all multiplayer calls made to the servers multiplayer interface
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), self.get_path())

func _ready() -> void:
	if instance == null:
		instance = self
		world_manager = $World
	else:
		queue_free()

func host_with_defaults() -> void:
	host(host_port)

func host(port: int) -> void:
	# Assign a new server peer
	var server_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	
	# Attempt to open a server on the given port
	var server_result: int = server_peer.create_server(port)
	match(server_result):
		OK:
			# Server started, set up the server peer
			multiplayer.multiplayer_peer = server_peer
			server_started.emit()
		_:
			# Server failed to start, free up this server node
			get_parent().queue_free()
			return

	multiplayer.peer_connected.connect(
		func(peer_id: int):
			print("%s - Client connected: %s" % [name, str(peer_id)])
	)

	multiplayer.peer_disconnected.connect(
		func(peer_id: int):
			print("%s - Client disconnected: " % [name, str(peer_id)])
	)
	