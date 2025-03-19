extends MultiplayerSynchronizer
class_name PlayerMobileSynchronizer

@export var owner_sync: bool = false
var player_mobile: PlayerMobile

func setup(type: int) -> void:
	#player_mobile = get_parent()

	#if multiplayer.is_server():
	if type == 0:
		if owner_sync:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_multiplayer_authority(player_mobile.owner_id)
			add_visibility_filter(
				func(peer_id: int) -> bool:
					if multiplayer.is_server():
						Debugger.log("OWNER_SYNC: %s is visible to server." % [player_mobile.owner_id], self)
						return true
					var is_visible: bool = player_mobile.current_zonemap.zonemap_id == Client.instance.current_zonemap.zonemap_id && peer_id == player_mobile.owner_id
					Debugger.log("OWNER_SYNC: %s visiblity to %s: %s" % [player_mobile.owner_id, Client.instance.player_id, is_visible], self)
					return is_visible
			)
		else:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_multiplayer_authority(player_mobile.owner_id)
			add_visibility_filter(
				func(peer_id: int) -> bool:
					if multiplayer.is_server():
						Debugger.log("REMOTE_SYNC: %s is visible to server." % [player_mobile.owner_id], self)
						return true
					var is_visible: bool = player_mobile.current_zonemap.zonemap_id == Client.instance.current_zonemap.zonemap_id && peer_id != player_mobile.owner_id
					Debugger.log("REMOTE_SYNC: %s visibility to %s: %s" % [player_mobile.owner_id, Client.instance.player_id, is_visible], self)
					return is_visible
			)
	#elif player_mobile.is_owner():
	elif type == 1:
		if owner_sync:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_multiplayer_authority(player_mobile.owner_id)
			add_visibility_filter(
				func(peer_id: int) -> bool:
					if multiplayer.is_server():
						Debugger.log("OWNER_SYNC: %s is visible to server." % [player_mobile.owner_id], self)
						return true
					var is_visible: bool = player_mobile.current_zonemap.zonemap_id == Client.instance.current_zonemap.zonemap_id && peer_id == player_mobile.owner_id
					Debugger.log("OWNER_SYNC: %s visiblity to %s: %s" % [player_mobile.owner_id, Client.instance.player_id, is_visible], self)
					return is_visible
			)
		else:
			process_mode = Node.PROCESS_MODE_DISABLED
	else:
		if owner_sync:
			process_mode = Node.PROCESS_MODE_DISABLED
		else:
			process_mode = Node.PROCESS_MODE_INHERIT
			set_multiplayer_authority(player_mobile.owner_id)
			add_visibility_filter(
				func(peer_id: int) -> bool:
					if multiplayer.is_server():
						Debugger.log("REMOTE_SYNC: %s is visible to server." % [player_mobile.owner_id], self)
						return true
					var is_visible: bool = player_mobile.current_zonemap.zonemap_id == Client.instance.current_zonemap.zonemap_id && peer_id != player_mobile.owner_id
					Debugger.log("REMOTE_SYNC: %s visibility to %s: %s" % [player_mobile.owner_id, Client.instance.player_id, is_visible], self)
					return is_visible
			)
