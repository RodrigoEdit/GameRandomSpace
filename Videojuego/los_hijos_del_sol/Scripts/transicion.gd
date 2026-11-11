extends CanvasLayer

var cambiando: bool = false
var _final_overlay: Control = null


func _ready() -> void:
	layer = 120


@rpc("authority", "call_local", "reliable")
func finalizar_juego() -> void:
	if _final_overlay != null:
		return

	_final_overlay = ColorRect.new()
	_final_overlay.color = Color(0.015, 0.02, 0.06, 0.94)
	_final_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_final_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_final_overlay)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_final_overlay.add_child(centro)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 18)
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "¡JUEGO COMPLETADO!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 48)
	contenido.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Los Hijos del Sol"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 24)
	contenido.add_child(subtitulo)

	var volver := Button.new()
	volver.text = "Volver al menú"
	volver.custom_minimum_size = Vector2(220, 48)
	volver.pressed.connect(_volver_al_menu)
	contenido.add_child(volver)

	var salir := Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size = Vector2(220, 48)
	salir.pressed.connect(func(): get_tree().quit())
	contenido.add_child(salir)

	DebugLogger.log_info("Partida completada")


func _volver_al_menu() -> void:
	if _final_overlay:
		_final_overlay.queue_free()
		_final_overlay = null
	get_tree().change_scene_to_file("res://Scenes/UI/menulhds.tscn")


# El servidor puede ordenar la transición en ambos equipos.
@rpc("authority", "call_local", "reliable")
func cambiar_nivel(ruta: String) -> void:
	if cambiando:
		return

	if not ResourceLoader.exists(ruta):
		push_error("No existe la escena: " + ruta)
		DebugLogger.log_error("Escena inexistente: " + ruta)
		return

	cambiando = true
	DebugLogger.log_info("Iniciando transición a " + ruta)

	var pantalla := get_viewport().get_visible_rect().size
	var mitad := pantalla.x / 2.0

	# Bloquear clics durante la transición.
	var bloqueo := Control.new()
	add_child(bloqueo)
	bloqueo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloqueo.mouse_filter = Control.MOUSE_FILTER_STOP

	var izquierda := ColorRect.new()
	izquierda.color = Color.BLACK
	izquierda.size = Vector2(0, pantalla.y)
	bloqueo.add_child(izquierda)

	var derecha := ColorRect.new()
	derecha.color = Color.BLACK
	derecha.position = Vector2(pantalla.x, 0)
	derecha.size = Vector2(0, pantalla.y)
	bloqueo.add_child(derecha)

	var centro := CenterContainer.new()
	centro.size = pantalla
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloqueo.add_child(centro)

	var texto := Label.new()
	texto.text = "¡NIVEL 1 COMPLETADO!"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 45)
	texto.modulate.a = 0.0
	centro.add_child(texto)

	# Cerrar el telón.
	var cierre := create_tween().set_parallel(true)
	cierre.tween_property(izquierda, "size:x", mitad + 5.0, 1.2)
	cierre.tween_property(derecha, "size:x", mitad + 5.0, 1.2)
	cierre.tween_property(derecha, "position:x", mitad - 5.0, 1.2)
	await cierre.finished

	# Mostrar el mensaje.
	var mostrar := create_tween()
	mostrar.tween_property(texto, "modulate:a", 1.0, 0.5)
	await mostrar.finished

	await get_tree().create_timer(2.0).timeout

	var ocultar := create_tween()
	ocultar.tween_property(texto, "modulate:a", 0.0, 0.4)
	await ocultar.finished

	# Limpiar los despawns mientras ambos equipos aun tienen el nivel anterior.
	# Si cambiamos primero, los paquetes llegan a un MultiplayerSpawner inexistente.
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		var spawner := get_tree().current_scene.get_node_or_null("MultiplayerSpawner") as MultiplayerSpawner
		if spawner:
			for player in get_tree().get_nodes_in_group("player"):
				if is_instance_valid(player) and spawner.has_method("despawn"):
					spawner.despawn(player)
			await get_tree().create_timer(0.25).timeout

	# Cargar el mapa mientras el telón está cerrado.
	var error := get_tree().change_scene_to_file(ruta)

	if error == OK:
		await get_tree().scene_changed
		DebugLogger.log_info("Escena cargada: " + ruta)
	else:
		push_error("No se pudo cargar el nivel. Código: %s" % error)
		DebugLogger.log_error("No se pudo cargar escena %s. Código: %s" % [ruta, error])

	# Abrir el telón sobre el nuevo mapa.
	var apertura := create_tween().set_parallel(true)
	apertura.tween_property(izquierda, "size:x", 0.0, 1.2)
	apertura.tween_property(derecha, "size:x", 0.0, 1.2)
	apertura.tween_property(derecha, "position:x", pantalla.x, 1.2)
	await apertura.finished

	bloqueo.queue_free()
	cambiando = false
