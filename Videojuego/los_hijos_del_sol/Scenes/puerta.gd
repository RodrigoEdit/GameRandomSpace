extends StaticBody2D

@export var items_requeridos: int = 3
var items_actuales: int = 0
var jugador_cerca: bool = false
var abierta: bool = false

@onready var label: Label = $Label
@onready var colision_fisica: CollisionShape2D = $CollisionShape2D
#@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	label.visible = false
	$Area2D.body_entered.connect(_on_area_2d_body_entered)
	$Area2D.body_exited.connect(_on_area_2d_body_exited)
	ItemPopupManager.item_accepted.connect(_on_item_accepted)


func _on_item_accepted(_item: ItemData) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		registrar_item.rpc_id(1)
	else:
		_registrar_item()


@rpc("any_peer", "reliable")
func registrar_item() -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_registrar_item()


func _registrar_item() -> void:
	if abierta:
		return
	items_actuales += 1
	print("Objeto recogido: ", items_actuales, "/", items_requeridos)
	if items_actuales >= items_requeridos:
		if multiplayer.has_multiplayer_peer():
			abrir_puerta.rpc()
		else:
			abrir_puerta()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Detecta si se presiona la tecla E físicamente o la acción 'interact'
		if event.keycode == KEY_E or event.is_action_pressed("interact"):
			if jugador_cerca:
				intentar_abrir()
			else:
				print("Presionaste E, pero el jugador NO está dentro del área")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# El nombre cambia a "1" o "2" al hacer spawn; el grupo no cambia.
	if body.is_in_group("player"):
		jugador_cerca = true
		mostrar_mensaje("[E] Interactuar")
		print("Jugador entró al área de la puerta")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador_cerca = false
		label.visible = false
		print("Jugador salió del área de la puerta")

func intentar_abrir() -> void:
	if abierta:
		return
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

@rpc("authority", "call_local", "reliable")
func abrir_puerta() -> void:
	if abierta:
		return
	abierta = true
	colision_fisica.set_deferred("disabled", true)
	#color_rect.visible = false
	label.visible = false
