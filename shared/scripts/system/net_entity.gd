extends Node
class_name NetEntity

enum EntityType {
	PLAYER_MOBILE,
	BASE_MOBILE,
	MAP
}

var current_zonemap: ZoneMap
var sync_enabled: bool = false
