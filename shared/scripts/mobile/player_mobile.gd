extends BaseMobile
class_name PlayerMobile

@export var sync_rate: float = 0.1
var sync_counter: float = 0
var has_synced: bool = false

var prev_sync_data: Dictionary[StringName,Variant]
var sync_data: Dictionary[StringName,Variant] = {
	&"position": Vector3.ZERO,
	&"rotation": Vector3.ZERO
}

var prev_anim_id: StringName
var current_anim_id: StringName = &"idle"

func _ready() -> void:
	super._ready()
	# IF we're the server
	if multiplayer.is_server():
		# Tell all other clients to spawn this player
		pass
	# If we're the owning client
	elif is_owner():
		Client.instance.acquire_player_control()
		sync_data.set(&"sender_id", owner_id)
		sync_data.set(&"node_path", Client.instance.get_path_to(self))
		prev_anim_id = current_anim_id
		anim_player.play(current_anim_id)
	# If we're a remote client
	else:
		sync_counter = sync_rate
		prev_sync_data = sync_data
		prev_anim_id = current_anim_id
		#anim_player.play(current_anim_id)

func _process(delta: float) -> void:
	# Are we the owning client?
	if is_owner():
		sync_counter += delta
		# Are we ready to sync?
		if sync_counter >= sync_rate:
			# Is our position and/or rotation different from last sync?
			if sync_data.get(&"position") != global_position || sync_data.get(&"rotation") != global_rotation:
				sync_data.set(&"position", global_position)
				sync_data.set(&"rotation", global_rotation)
			# If not, reset sync_counter
			else:
				sync_counter = 0
			# If we had a new position and/or rotation sync_counter will be > 0
			if sync_counter > 0:
				# Send local position to server
				Client.net_bridge.send_client_to_server_unreliable.rpc(NetBridge.PacketType.PLAYER_SYNC_POS, var_to_bytes(sync_data))
				sync_counter = 0
			
			if current_anim_id != anim_player.current_animation:
				prev_anim_id = current_anim_id
				current_anim_id = anim_player.current_animation
				var anim_sync_data: Dictionary[StringName,Variant] = {
					&"node_path": Client.instance.get_path_to(self),
					&"current_anim": current_anim_id
				}
				Client.net_bridge.send_client_to_server_unreliable.rpc(NetBridge.PacketType.PLAYER_ANIM_SYNC, var_to_bytes(anim_sync_data))
	
	# Are we a remote client ready to sync?
	elif not multiplayer.is_server() && sync_counter < sync_rate:
		if !has_synced:
			global_position = sync_data.get(&"position")
			global_rotation = sync_data.get(&"rotation")
			prev_sync_data = sync_data
		else:
			var from_position: Vector3 = prev_sync_data.get(&"position")
			var to_position: Vector3 = sync_data.get(&"position")
			global_position = lerp(from_position, to_position, clampf(1.0 / (sync_rate / sync_counter), 0.0, 1.0))
			global_rotation = sync_data.get(&"rotation")
			if anim_player.has_animation(current_anim_id):
				if anim_player.current_animation != current_anim_id:
					anim_player.play(current_anim_id)
			sync_counter += delta

func update_position(data: Dictionary[StringName,Variant]) -> void:
	# Server does not need to do any interpolation
	if multiplayer.is_server():
		sync_data = data
		global_position = sync_data.get(&"position")
		global_rotation = sync_data.get(&"rotation")
	# Set up interpolation for remote clients
	elif not is_owner():
		prev_sync_data.set(&"position", global_position)
		prev_sync_data.set(&"rotation", global_rotation)
		sync_data = data
		sync_counter = 0
		has_synced = true

func update_anim(data: Dictionary[StringName,Variant]) -> void:
	if not multiplayer.is_server() && not is_owner():
		# Process anims
		current_anim_id = data.get(&"current_anim")
		#anim_player.play(data.get(&"current_anim"))

func refresh_zonemap() -> void:
	if is_owner():
		sync_data.set(&"node_path", Client.instance.get_path_to(self))

func get_current_data() -> Dictionary[StringName,Variant]:
	var data: Dictionary[StringName,Variant] = {
		&"entity_type": NetEntity.EntityType.PLAYER_MOBILE,
		&"mobile_config_id": mobile_config_id,
		&"player_id": owner_id,
		&"name": mobile_name,
		&"position": global_position,
		&"rotation": global_rotation,
		&"current_anim": current_anim_id,
	}
	if multiplayer.is_server():
		data.set(&"node_path", Server.instance.get_path_to(self))
	else:
		data.set(&"node_path", Client.instance.get_path_to(self))
	return data
