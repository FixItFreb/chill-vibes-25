extends Control

@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var dedicated_button: Button = %DedicatedButton
@onready var start_game_button: Button = %StartGameButton
@onready var name_text_entry: LineEdit = %NameTextEntry

@onready var setup_panel: PanelContainer = %SetupPanel
@onready var connect_panel: PanelContainer = %ConnectedPanel

@onready var server_node: Server = get_node("/root/GameMain/ServerWorld/ServerMain")
@onready var client_node: Client = get_node("/root/GameMain/ClientMain")

func _ready():
	host_button.pressed.connect(host_button_press)
	join_button.pressed.connect(join_button_press)
	dedicated_button.pressed.connect(dedicated_button_press)
	start_game_button.pressed.connect(start_game_button_press)
	name_text_entry.text_changed.connect(update_player_name)

	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg.begins_with("-player_name"):
			var split_args: PackedStringArray = arg.split("=")
			if split_args.size() > 1:
				name_text_entry.text = arg.split("=")[1]
	
	update_player_name(name_text_entry.text)

func host_button_press() -> void:
	server_node.on_server_started.connect(
		func():
			#visible = false
			client_node.join_with_defaults()
			setup_panel.visible = false
			connect_panel.visible = true,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	server_node.host_with_defaults()

func join_button_press() -> void:
	client_node.multiplayer.connected_to_server.connect(
		func():
			#visible = false,
			setup_panel.visible = false
			connect_panel.visible = true,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	client_node.join_with_defaults()

# TODO: Add some server specific logging UI here
func dedicated_button_press() -> void:
	server_node.on_server_started.connect(
		func():
			visible = false,
		ConnectFlags.CONNECT_ONE_SHOT
	)
	server_node.host_with_defaults()

func update_player_name(new_name: String) -> void:
	Client.instance.player_name = new_name

func start_game_button_press() -> void:
	visible = false
	client_node.request_spawn_player()
