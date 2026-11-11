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
	
	# Si el nivel tiene la función de cambio sincronizado, la usamos
	if nivel_actual.has_method("cambiar_a_nivel_2"):
		nivel_actual.cambiar_a_nivel_2()
	else:
		# Respaldo si estás probando fuera de red
		get_tree().change_scene_to_file(siguiente_nivel)
