# This is a character that lives on the server and is responsible for broadcasting all necessary updates to clients
extends Node3D

# ServerSync broadcasts updates for this character to all connected clients
@onready var server_sync: MultiplayerSynchronizer = $ServerSync
# OwnerSync receives updates from the owning client of this character
@onready var owner_sync: MultiplayerSynchronizer = $OwnerSync

func on_enter_sync_range(client_in_range: Area3D) -> void:
    # If this is the owning character ignore
    if client_in_range == $ClientRange:
        return

    # Get the ID for the owner of the character that just entered sync range
    var peer_id: int = client_in_range.get_multiplayer_authority()
    # Set this character visible so it can sync to the character that just entered sync range
    server_sync.set_visibility_for(peer_id, true)

func on_exit_sync_range(client_out_of_range: Area3D) -> void:
    # If this is the owning character ignore
    if client_out_of_range == $ClientRange:
        return
    
    # Get the ID for the owner of the character that just left sync range
    var peer_id: int = client_out_of_range.get_multiplayer_authority()
    # Set this character invisible to stop syncing to the character that just left sync range
    server_sync.set_visibility_for(peer_id, false)
