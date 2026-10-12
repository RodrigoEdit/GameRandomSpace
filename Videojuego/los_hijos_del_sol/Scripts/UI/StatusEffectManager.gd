class_name StatusEffectManager
extends Node
## Gestiona buffs: duración, renovación y eliminación.

signal effect_added(effect: StatusEffect)
signal effect_removed(effect: StatusEffect)

var _effects: Array[StatusEffect] = []


func _process(delta: float) -> void:
	# Recorremos al revés para poder borrar mientras iteramos.
	for i in range(_effects.size() - 1, -1, -1):
		var effect: StatusEffect = _effects[i]
		if not effect.has_timer():
			continue
		effect.time_left -= delta
		if effect.time_left <= 0.0:
			_remove_at(i)


func apply_speed(multiplier: float, stamina_multiplier: float, duration: float, icon: Texture2D) -> void:
	var effect: StatusEffect = _find(StatusEffect.Kind.SPEED)
	if effect == null:
		effect = StatusEffect.new(StatusEffect.Kind.SPEED, icon, duration)
		_effects.append(effect)
		effect.speed_multiplier = multiplier
		effect.stamina_multiplier = stamina_multiplier
		effect_added.emit(effect)
	else:
		# Volver a consumir RENUEVA la duración en vez de apilar.
		effect.speed_multiplier = multiplier
		effect.stamina_multiplier = stamina_multiplier
		effect.duration = duration
		effect.time_left = duration


func apply_shield(hits: int, icon: Texture2D) -> void:
	var effect: StatusEffect = _find(StatusEffect.Kind.SHIELD)
	if effect == null:
		effect = StatusEffect.new(StatusEffect.Kind.SHIELD, icon)
		effect.hits_left = hits
		_effects.append(effect)
		effect_added.emit(effect)
	else:
		effect.hits_left = hits


## Devuelve true si el escudo absorbió el golpe.
func absorb_hit() -> bool:
	var effect: StatusEffect = _find(StatusEffect.Kind.SHIELD)
	if effect == null:
		return false
	effect.hits_left -= 1
	if effect.hits_left <= 0:
		remove_effect(effect)
	return true


func remove_effect(effect: StatusEffect) -> void:
	var index: int = _effects.find(effect)
	if index >= 0:
		_remove_at(index)


func get_speed_multiplier() -> float:
	var result: float = 1.0
	for effect in _effects:
		if effect.kind == StatusEffect.Kind.SPEED:
			result *= effect.speed_multiplier
	return result


func get_stamina_multiplier() -> float:
	var result: float = 1.0
	for effect in _effects:
		if effect.kind == StatusEffect.Kind.SPEED:
			result *= effect.stamina_multiplier
	return result


func _find(kind: StatusEffect.Kind) -> StatusEffect:
	for effect in _effects:
		if effect.kind == kind:
			return effect
	return null


func _remove_at(index: int) -> void:
	var effect: StatusEffect = _effects[index]
	_effects.remove_at(index)
	effect_removed.emit(effect)
