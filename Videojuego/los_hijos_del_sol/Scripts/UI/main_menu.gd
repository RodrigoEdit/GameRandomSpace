extends Control

@export_file("*.tscn") var level_scene_path: String = "res://Scenes/level1.tscn"
@export_file("*.tscn") var options_scene_path: String = ""
@export_file("*.tscn") var credits_scene_path: String = ""

# Referencias a nodos
@onready var btn_play: Button = $ButtonsGroup/BtnPlay
@onready var btn_options: Button = $ButtonsGroup/BtnOptions
@onready var btn_credits: Button = $ButtonsGroup/BtnCredits
@onready var btn_quit: Button = $ButtonsGroup/BtnQuit
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var is_transitioning: bool = false
var default_volume_db: float = 0.0
var overlay_panel: Control = null

func _ready() -> void:
	btn_play.grab_focus.call_deferred()
	btn_options.disabled = false
	btn_credits.disabled = false

	# Guardar el volumen configurado en el inspector
	if audio_player:
		default_volume_db = audio_player.volume_db
		audio_player.volume_db = -40.0  # Empezar en silencio para fade-in de audio
		audio_player.play()
	
	# La pantalla arranca completamente en negro y bloqueando clics
	fade_overlay.modulate.a = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Conexión de botones
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_options.pressed.connect(_on_btn_options_pressed)
	btn_credits.pressed.connect(_on_btn_credits_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	# Iniciar la aparición lenta del menú
	_fade_in_menu()

func _fade_in_menu() -> void:
	var intro_tween = create_tween().set_parallel(true)
	
	# 1. Desvanecer la pantalla negra lentamente (2.0 segundos)
	intro_tween.tween_property(fade_overlay, "modulate:a", 0.0, 2.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. Subir la música suavemente de la nada a su volumen normal
	if audio_player:
		intro_tween.tween_property(audio_player, "volume_db", default_volume_db, 2.0)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	
	# 3. Al terminar el desvanecimiento, permitir interactuar con los botones
	intro_tween.chain().tween_callback(func():
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
	
func _transition_to_scene(target_path: String) -> void:
	if is_transitioning:
		return
		
	if target_path.is_empty():
		push_error("¡No se ha asignado una ruta de escena en el Inspector!")
		return

	is_transitioning = true
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var outro_tween = create_tween().set_parallel(true)
	
	outro_tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.8)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	if audio_player and audio_player.playing:
		outro_tween.tween_property(audio_player, "volume_db", -40.0, 1.8)
	
	outro_tween.chain().tween_callback(func():
		get_tree().change_scene_to_file(target_path)
	)
	
func _on_btn_play_pressed() -> void:
	_transition_to_scene(level_scene_path)

func _change_to_level() -> void:
	if level_scene_path != "":
		get_tree().change_scene_to_file(level_scene_path)
	else:
		print("¡Asigna la escena del nivel en el Inspector!")

func _on_btn_options_pressed() -> void:
	if options_scene_path.is_empty():
		_show_options()
	else:
		_transition_to_scene(options_scene_path)

func _on_btn_credits_pressed() -> void:
	if credits_scene_path.is_empty():
		_show_credits()
	else:
		_transition_to_scene(credits_scene_path)


func _show_options() -> void:
	var contenido := _crear_overlay("OPCIONES")

	var volumen_label := Label.new()
	volumen_label.text = "VOLUMEN DE MÚSICA"
	contenido.add_child(volumen_label)

	var volumen := HSlider.new()
	volumen.min_value = 0.0
	volumen.max_value = 1.0
	volumen.step = 0.01
	volumen.value = inverse_lerp(-40.0, 0.0, audio_player.volume_db)
	volumen.custom_minimum_size = Vector2(360, 32)
	volumen.value_changed.connect(func(valor: float):
		audio_player.volume_db = lerp(-40.0, 0.0, valor)
	)
	contenido.add_child(volumen)

	var pantalla := CheckButton.new()
	pantalla.text = "PANTALLA COMPLETA"
	pantalla.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	pantalla.toggled.connect(func(activa: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if activa else DisplayServer.WINDOW_MODE_WINDOWED)
	)
	contenido.add_child(pantalla)

	_agregar_boton_volver(contenido)


func _show_credits() -> void:
	var contenido := _crear_overlay("CRÉDITOS")

	var texto := Label.new()
	texto.text = "LOS HIJOS DEL SOL\n\nUna aventura cooperativa inspirada en los Andes.\n\nDesarrollado por Rodrigo Elguera Y Marco Alanya\nGracias por jugar."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 18)
	contenido.add_child(texto)

	_agregar_boton_volver(contenido)


func _crear_overlay(titulo: String) -> VBoxContainer:
	if overlay_panel:
		overlay_panel.queue_free()

	overlay_panel = ColorRect.new()
	overlay_panel.color = Color(0.01, 0.02, 0.05, 0.96)
	overlay_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay_panel)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_panel.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 360)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	for lado in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margen.add_theme_constant_override(lado, 32)
	panel.add_child(margen)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 18)
	margen.add_child(contenido)

	var encabezado := Label.new()
	encabezado.text = titulo
	encabezado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encabezado.add_theme_font_size_override("font_size", 30)
	contenido.add_child(encabezado)
	return contenido


func _agregar_boton_volver(contenido: VBoxContainer) -> void:
	var volver := Button.new()
	volver.text = "VOLVER"
	volver.custom_minimum_size = Vector2(220, 48)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volver.pressed.connect(_cerrar_overlay)
	contenido.add_child(volver)


func _cerrar_overlay() -> void:
	if overlay_panel:
		overlay_panel.queue_free()
		overlay_panel = null
	btn_play.grab_focus.call_deferred()

func _on_btn_quit_pressed() -> void:
	if is_transitioning:
		return
	get_tree().quit()
