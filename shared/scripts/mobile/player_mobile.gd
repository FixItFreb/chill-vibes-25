extends BaseMobile
class_name PlayerMobile

func _ready() -> void:
	super._ready()
	# This is the owning client of this player
	if is_owner():
		owner_sync.set_visibility_for(1, true)
		remote_sync.set_visibility_for(1, true)
		remote_sync.set_visibility_for(owner_id, false)
		current_zonemap.on_player_join.connect(add_player_visibility)
		current_zonemap.on_player_leave.connect(remove_player_visibility)
		refresh_player_visibility()

func add_player_visibility(player: PlayerMobile) -> void:
	remote_sync.set_visibility_for(player.owner_id, true)

func remove_player_visibility(player: PlayerMobile) -> void:
	remote_sync.set_visibility_for(player.owner_id, false)

# Visibility for a synchroniser _must_ be set from the owning player
func refresh_player_visibility() -> void:
	if is_owner():
		for player_id: int in current_zonemap.players_in_zone:
			remote_sync.set_visibility_for(player_id, true)

func clear_player_visibility() -> void:
	if is_owner():
		remote_sync.set_visibility_for(0, false)
		