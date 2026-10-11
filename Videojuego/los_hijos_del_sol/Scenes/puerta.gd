extends StaticBody2D

@export var items_requeridos: int = 3
var items_actuales: int = 0
var jugador_cerca: bool = false

@onready var label: Label = $Label
@onready var colision_fisica: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	label.visible = false
	$Area2D.body_entered.connect(_on_area_2d_body_entered)
	$Area2D.body_exited.connect(_on_area_2d_body_exited)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Detecta si se presiona la tecla E físicamente o la acción 'interact'
		if event.keycode == KEY_E or event.is_action_pressed("interact"):
			if jugador_cerca:
				intentar_abrir()
			else:
				print("Presionaste E, pero el jugador NO está dentro del área")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Detecta a Player_one o Player_two
	if "Player" in body.name:
		jugador_cerca = true
		mostrar_mensaje("[E] Interactuar")
		print("Jugador entró al área de la puerta")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if "Player" in body.name:
		jugador_cerca = false
		label.visible = false
		print("Jugador salió del área de la puerta")

func intentar_abrir() -> void:
	if items_actuales >= items_requeridos:
		mostrar_mensaje("¡Puerta abierta!")
		abrir_puerta()
	else:
		var faltantes = items_requeridos - items_actuales
		mostrar_mensaje("Bloqueada. Faltan " + str(faltantes) + " ítems.")
		print("Puerta bloqueada. Faltan items.")

func mostrar_mensaje(texto: String) -> void:
	label.text = texto
	label.visible = true

func abrir_puerta() -> void:
	colision_fisica.set_deferred("disabled", true)
	color_rect.visible = false
	label.visible = false
