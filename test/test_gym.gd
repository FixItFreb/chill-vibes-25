extends Node

@export var player_input: PlayerInputHandler

func _ready():
	player_input.set_controlled(get_node("PlayerMobile"))
	#player_input.set_controlled(get_node("PlayerCharacter"))
