extends Control

@export_file("*.tscn") var level_scene_path: String = ""
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

func _ready() -> void:
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

func _on_btn_play_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Bloquear clics mientras desaparece el menú
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var outro_tween = create_tween().set_parallel(true)
	
	# Oscurecer lentamente para ir al juego (1.8 segundos)
	outro_tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.8)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Desvanecer la música hacia silencio
	if audio_player and audio_player.playing:
		outro_tween.tween_property(audio_player, "volume_db", -40.0, 1.8)
	
	outro_tween.chain().tween_callback(_change_to_level)

func _change_to_level() -> void:
	if level_scene_path != "":
		get_tree().change_scene_to_file(level_scene_path)
	else:
		print("¡Asigna la escena del nivel en el Inspector!")

func _on_btn_options_pressed() -> void:
	if options_scene_path != "":
		get_tree().change_scene_to_file(options_scene_path)

func _on_btn_credits_pressed() -> void:
	if credits_scene_path != "":
		get_tree().change_scene_to_file(credits_scene_path)

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
