extends Area2D

var nivel_terminado: bool = false

func _ready() -> void:
	body_entered.connect(_cuando_entra_cuerpo)

func _cuando_entra_cuerpo(body: Node2D) -> void:
	# Verificamos que sea exclusivamente la jugadora (y no el Skeleton)
	if not nivel_terminado and ("Player" in body.name or "player" in body.name):
		nivel_terminado = true
		print("¡Nivel 1 completado! Cerrando telón...")
		
		# Detener a la jugadora y ponerla en animación idle
		body.set_physics_process(false)
		if body.has_node("AnimatedSprite2D"):
			body.get_node("AnimatedSprite2D").play("idle")
		
		# Llamar al telón de forma segura
		call_deferred("cerrar_telon_y_terminar")

func cerrar_telon_y_terminar() -> void:
	# 1. Crear capa superior por encima de cámaras y HUD
	var capa_telon := CanvasLayer.new()
	capa_telon.layer = 120
	get_tree().root.add_child(capa_telon)
	
	# Obtener el tamaño real de la ventana del juego
	var tamano_pantalla := get_viewport().get_visible_rect().size
	var mitad_ancho := tamano_pantalla.x / 2.0
	
	# 2. Telón Izquierdo
	var telon_izq := ColorRect.new()
	telon_izq.color = Color.BLACK
	telon_izq.position = Vector2(0, 0)
	telon_izq.size = Vector2(0, tamano_pantalla.y)
	capa_telon.add_child(telon_izq)
	
	# 3. Telón Derecho
	var telon_der := ColorRect.new()
	telon_der.color = Color.BLACK
	telon_der.position = Vector2(tamano_pantalla.x, 0)
	telon_der.size = Vector2(0, tamano_pantalla.y)
	capa_telon.add_child(telon_der)
	
	# 4. Contenedor para centrar el texto sí o sí en toda la pantalla
	var contenedor := CenterContainer.new()
	contenedor.position = Vector2.ZERO
	contenedor.size = tamano_pantalla
	capa_telon.add_child(contenedor)
	
	var texto_final := Label.new()
	texto_final.text = "¡NIVEL 1 COMPLETADO!\nFIN DEL JUEGO"
	texto_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_final.add_theme_font_size_override("font_size", 45)
	texto_final.add_theme_color_override("font_color", Color.WHITE)
	texto_final.modulate.a = 0.0 # Empieza invisible
	contenedor.add_child(texto_final)
	
	# 5. Tween 1: Cerrar ambos lados del telón al mismo tiempo (1.2 segundos)
	var tween_telon := get_tree().create_tween().set_parallel(true)
	tween_telon.tween_property(telon_izq, "size:x", mitad_ancho + 5.0, 1.2)
	tween_telon.tween_property(telon_der, "size:x", mitad_ancho + 5.0, 1.2)
	tween_telon.tween_property(telon_der, "position:x", mitad_ancho - 5.0, 1.2)
	
	await tween_telon.finished
	
	# 6. Tween 2: Mostrar el texto de victoria (0.8 segundos)
	var tween_texto := get_tree().create_tween()
	tween_texto.tween_property(texto_final, "modulate:a", 1.0, 0.8)
	
	await tween_texto.finished
	
	# 7. Esperar 3 segundos leyendo el cartel y cerrar el juego
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()
