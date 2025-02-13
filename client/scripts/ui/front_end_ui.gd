extends Control

@export var host_button: Button
@export var join_button: Button

func _ready():
	host_button.pressed.connect(host_button_press)
	join_button.pressed.connect(join_button_press)

func host_button_press() -> void:
	var server_node: Server = get_node("/root/GameMain/ServerWorld/ServerMain") as Server
	var client_node: Client = get_node("/root/GameMain/ClientMain") as Client
	server_node.server_started.connect(
		func():
			visible = false
			client_node.join_with_defaults(),
		ConnectFlags.CONNECT_ONE_SHOT
	)
	server_node.host_with_defaults()

func join_button_press() -> void:
	var client_node: Client = get_node("/root/GameMain/ClientMain") as Client
	client_node.multiplayer.connected_to_server.connect(
		func():
			visible = false,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	client_node.join_with_defaults()
	
