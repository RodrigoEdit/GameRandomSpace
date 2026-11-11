extends CanvasLayer

var cambiando: bool = false


func _ready() -> void:
	layer = 120


# El servidor puede ordenar la transición en ambos equipos.
@rpc("authority", "call_local", "reliable")
func cambiar_nivel(ruta: String) -> void:
	if cambiando:
		return

	if not ResourceLoader.exists(ruta):
		push_error("No existe la escena: " + ruta)
		return

	cambiando = true

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

	# Cargar el mapa mientras el telón está cerrado.
	var error := get_tree().change_scene_to_file(ruta)

	if error == OK:
		await get_tree().scene_changed
	else:
		push_error("No se pudo cargar el nivel. Código: %s" % error)

	# Abrir el telón sobre el nuevo mapa.
	var apertura := create_tween().set_parallel(true)
	apertura.tween_property(izquierda, "size:x", 0.0, 1.2)
	apertura.tween_property(derecha, "size:x", 0.0, 1.2)
	apertura.tween_property(derecha, "position:x", pantalla.x, 1.2)
	await apertura.finished

	bloqueo.queue_free()
	cambiando = false
