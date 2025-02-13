extends Node
class_name Damageable

var invulnerable: bool = false

signal on_damaged(incoming: int)

func damage(incoming: int) -> void:
	if !invulnerable:
		on_damaged.emit(incoming)