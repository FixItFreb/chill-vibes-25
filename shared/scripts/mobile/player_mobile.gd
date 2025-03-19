extends BaseMobile
class_name PlayerMobile

@export var mobile_sync_scene: PackedScene

# func _enter_tree() -> void:
# 	if !multiplayer.is_server():
# 		if is_owner():
# 			get_node("ServerSync").free()
# 		else:
# 			get_node("OwnerSync").free()

func _ready() -> void:
	super._ready()
	# This is the server so it needs both owner and server syncs
	if multiplayer.is_server():	
		var owner_sync: PlayerMobileSynchronizer = mobile_sync_scene.instantiate()
		owner_sync.owner_sync = true
		owner_sync.name = "OwnerSync"
		owner_sync.player_mobile = self
		owner_sync.setup(0)
		add_child(owner_sync)
		var server_sync: PlayerMobileSynchronizer = mobile_sync_scene.instantiate()
		server_sync.name = "ServerSync"
		server_sync.player_mobile = self
		server_sync.setup(0)
		add_child(server_sync)
	# This is the owning client of this player so it needs only the owner sync
	elif is_owner():
		var owner_sync: PlayerMobileSynchronizer = mobile_sync_scene.instantiate()
		owner_sync.owner_sync = true
		owner_sync.name = "OwnerSync"
		owner_sync.player_mobile = self
		owner_sync.setup(1)
		add_child(owner_sync)
		Client.instance.acquire_player_control()
	# This is a remote player so it needs just the server sync
	else:
		var server_sync: PlayerMobileSynchronizer = mobile_sync_scene.instantiate()
		server_sync.name = "ServerSync"
		server_sync.player_mobile = self
		server_sync.setup(2)
		add_child(server_sync)
	

# func add_player_visibility(player: PlayerMobile) -> void:
# 	remote_sync.set_visibility_for(player.owner_id, true)

# func remove_player_visibility(player: PlayerMobile) -> void:
# 	remote_sync.set_visibility_for(player.owner_id, false)

# Visibility for a synchroniser _must_ be set from the owning player
# func refresh_player_visibility() -> void:
# 	if is_owner():
# 		for player_id: int in current_zonemap.players_in_zone:
# 			remote_sync.set_visibility_for(player_id, true)

# func clear_player_visibility() -> void:
# 	if is_owner():
# 		remote_sync.set_visibility_for(0, false)
		
