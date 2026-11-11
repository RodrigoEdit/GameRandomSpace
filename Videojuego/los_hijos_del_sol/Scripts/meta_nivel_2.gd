extends Area2D

var activada := false

func _ready() -> void:
	body_entered.connect(_cuando_entra_cuerpo)

func _cuando_entra_cuerpo(body: Node2D) -> void:
	if activada or not body.is_in_group("player"):
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	activada = true
	body.set_physics_process(false)
	if multiplayer.has_multiplayer_peer():
		Transicion.finalizar_juego.rpc()
	else:
		Transicion.finalizar_juego()
