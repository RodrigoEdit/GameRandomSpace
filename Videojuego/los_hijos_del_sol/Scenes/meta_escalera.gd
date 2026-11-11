extends Area2D

@export_file("*.tscn") var siguiente_nivel: String = "res://Scenes/level2.tscn"

var nivel_terminado: bool = false


func _ready() -> void:
	body_entered.connect(_cuando_entra_cuerpo)


func _cuando_entra_cuerpo(body: Node2D) -> void:
	if nivel_terminado:
		return

	if not body.is_in_group("player"):
		return

	# En una partida en red, el servidor decide cuándo cambiar.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	nivel_terminado = true

	body.set_physics_process(false)

	var sprite := body.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	# Salir del callback de física antes de iniciar la transición.
	call_deferred("_iniciar_transicion")


func _iniciar_transicion() -> void:
	var nivel_actual = get_tree().current_scene
	
	# El nivel actual debe pedirle al servidor que ordene el cambio sincronizado.
	if nivel_actual.has_method("cambiar_a_nivel_2"):
		nivel_actual.cambiar_a_nivel_2()
	else:
		# Respaldo para niveles antiguos o pruebas sin red.
		if multiplayer.has_multiplayer_peer():
			push_error("El nivel actual no tiene cambiar_a_nivel_2(); no se cambia la escena en red.")
		else:
			Transicion.cambiar_nivel(siguiente_nivel)
