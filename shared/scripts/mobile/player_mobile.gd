extends BaseMobile
class_name PlayerMobile

func _ready():
	super._ready()
	damageable.on_damaged.connect(on_damage_received)

func on_damage_received(incoming: int) -> void:
	print("%s received %s damage." % [mobile_name, incoming])
