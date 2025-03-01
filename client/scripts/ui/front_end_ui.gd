extends Control

@export var host_button: Button
@export var join_button: Button
@export var dedicated_button: Button
@export var name_text_entry: LineEdit

func _ready():
	host_button.pressed.connect(host_button_press)
	join_button.pressed.connect(join_button_press)
	dedicated_button.pressed.connect(dedicated_button_press)
	name_text_entry.text_changed.connect(update_player_name)
	update_player_name(name_text_entry.text)

func host_button_press() -> void:
	var server_node: Server = get_node("/root/GameMain/ServerWorld/ServerMain") as Server
	var client_node: Client = get_node("/root/GameMain/ClientMain") as Client
	server_node.on_server_started.connect(
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

# TODO: Add some server specific logging UI here
func dedicated_button_press() -> void:
	var server_node: Server = get_node("/root/GameMain/ServerWorld/ServerMain") as Server
	server_node.on_server_started.connect(
		func():
			visible = false,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	server_node.host_with_defaults()

func update_player_name(new_name: String) -> void:
	Client.instance.player_name = new_name
