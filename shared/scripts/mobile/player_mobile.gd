extends BaseMobile
class_name PlayerMobile

@export var sync_rate: float = 0.1
var last_sync = 0

var sync_data: Dictionary[StringName,Variant] = {
	&"position": Vector3.ZERO,
	&"rotation": Vector3.ZERO
}

func _ready() -> void:
	super._ready()
	if multiplayer.is_server():
		# Tell all other clients to spawn this player
		pass
	elif is_owner():
		Client.instance.acquire_player_control()

func _process(delta: float) -> void:
	if is_owner():
		last_sync += delta
		if last_sync >= sync_rate:
			# Send local position to server
			sync_data.set(&"position", global_position)
			sync_data.set(&"rotation", global_rotation)
			sync_data.set(&"player_path", Client.instance.get_path_to(self))
			#sync_position.rpc(var_to_bytes(sync_data))
			Client.net_bridge.send_client_to_server_unreliable.rpc(NetBridge.DataType.PLAYER_SYNC_POS, var_to_bytes(sync_data))
			Debugger.log("Syncing...", self)
			last_sync = 0

#@rpc("authority", "call_remote", "unreliable")
func sync_position(bytes: PackedByteArray) -> void:
	#TODO: interpolate position
	var data: Dictionary[StringName,Variant] = bytes_to_var(bytes)
	global_position = data.get(&"position")
	global_rotation = data.get(&"rotation")
	Debugger.log("Honk", self)

func update_position(data: Dictionary[StringName,Variant]) -> void:
	if not is_owner():
		global_position = data.get(&"position")
		global_rotation = data.get(&"rotation")

@rpc
func test_rpc() -> void:
	Debugger.log("I received an RPC", self)

func add_player_visibility(players: Array[PlayerMobile]) -> void:
	pass

func remove_player_visibility(players: Array[PlayerMobile]) -> void:
	pass

func get_current_data() -> Dictionary[StringName,Variant]:
	var data: Dictionary[StringName,Variant] = {
		&"entity_type": NetEntity.EntityType.PLAYER_MOBILE,
		&"mobile_config_id": mobile_config_id,
		&"player_id": owner_id,
		&"player_name": mobile_name,
		&"player_pos": global_position,
		&"player_rot": global_rotation
	}
	return data
