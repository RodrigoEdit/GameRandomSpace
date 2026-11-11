extends Node2D

var sellos_activados: int = 0
const TOTAL_SELLOS: int = 4

# Referencia al nodo de la puerta
@onready var puerta: Node2D = $Puerta
@onready var colision_puerta: CollisionShape2D = $Puerta/CollisionShape2D

# Escenas de los jugadores para el spawn del Nivel 2
const PLAYER_ONE_SCENE = preload("res://Scenes/player_one.tscn")
const PLAYER_TWO_SCENE = preload("res://Scenes/player_two.tscn")

func _ready() -> void:
	# Conectar placas
	for placa in get_tree().get_nodes_in_group("placas"):
		placa.placa_activada.connect(_on_placa_activada)
		placa.placa_desactivada.connect(_on_placa_desactivada)

	# Esperar a que la red y ambas ventanas terminen de montar la escena
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_iniciar_spawn_retrasado.call_deferred()

func _iniciar_spawn_retrasado() -> void:
	# Pequeña pausa de 0.2 segundos para que el cliente cargue Level2 completamente
	await get_tree().create_timer(0.2).timeout
	
	spawning_player(1) # Host
	for peer_id in multiplayer.get_peers():
		spawning_player(peer_id) # Cliente
func spawning_player(id: int) -> void:
	var player: Node2D
	if id == 1:
		player = PLAYER_ONE_SCENE.instantiate()
	else:
		player = PLAYER_TWO_SCENE.instantiate()
		
	player.name = str(id)
	$spawn.add_child(player, true)
	
	if id == 1:
		player.global_position = $spawn.global_position
	else:
		player.global_position = $spawn.global_position + Vector2(25, 0)

func _on_placa_activada(tipo: String) -> void:
	sellos_activados += 1
	print("Sello correcto encajado: ", tipo, ". Total: ", sellos_activados, "/4")
	_verificar_puerta()

func _on_placa_desactivada(tipo: String) -> void:
	sellos_activados = max(0, sellos_activados - 1)
	print("Caja retirada de la placa: ", tipo, ". Total: ", sellos_activados, "/4")

func _verificar_puerta() -> void:
	if sellos_activados >= TOTAL_SELLOS:
		# Si estamos en red, el servidor ejecuta la apertura para todos
		if multiplayer.has_multiplayer_peer():
			if multiplayer.is_server():
				abrir_puerta.rpc()
		else:
			# Si estás probando en solitario con F6
			abrir_puerta()

@rpc("call_local", "reliable")
func abrir_puerta() -> void:
	print("¡Los 4 sellos están activados! Desbloqueando paso.")
	
	# Desactivar colisión
	if colision_puerta:
		colision_puerta.set_deferred("disabled", true)
	
	# Ocultar la puerta (o llamar a su método de abrir si tiene script)
	if puerta.has_method("abrir_puerta"):
		puerta.abrir_puerta()
	else:
		puerta.hide()
