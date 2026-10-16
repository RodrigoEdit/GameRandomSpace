extends CanvasLayer

const MAIN_MENU := "res://Scenes/UI/menulhds.tscn"

@onready var fade: ColorRect = $Fade
@onready var label: Label = $Label


func _ready() -> void:
	# Todo invisible al inicio
	fade.modulate.a = 0.0
	label.modulate.a = 0.0

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.died.connect(_on_player_died)
	else:
		push_warning("GameOver: no encontré al Player en el grupo 'player'.")


func _on_player_died() -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.5)   # pantalla a negro
	tween.tween_property(label, "modulate:a", 1.0, 1.0)  # aparece el texto
	tween.tween_interval(2.5)                            # pausa para leerlo
	await tween.finished
	get_tree().change_scene_to_file(MAIN_MENU)
