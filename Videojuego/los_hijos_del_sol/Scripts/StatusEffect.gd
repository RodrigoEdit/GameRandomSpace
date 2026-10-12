class_name StatusEffect
extends RefCounted
## Datos de un buff activo.

enum Kind { SPEED, SHIELD }

var kind: Kind
var icon: Texture2D
var duration: float = 0.0       # 0 = no caduca por tiempo (escudo)
var time_left: float = 0.0
var speed_multiplier: float = 1.0
var stamina_multiplier: float = 1.0
var hits_left: int = 0


func _init(p_kind: Kind, p_icon: Texture2D, p_duration: float = 0.0) -> void:
	kind = p_kind
	icon = p_icon
	duration = p_duration
	time_left = p_duration


func has_timer() -> bool:
	return duration > 0.0
