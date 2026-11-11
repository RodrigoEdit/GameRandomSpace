extends Node2D

var sellos_activados: int = 0
const TOTAL_SELLOS: int = 4
var jugadores_listos: Dictionary = {}
var spawn_realizado: bool = false

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

	# No publicar cajas hasta que el cliente haya terminado de cargar Level2.
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		for caja in get_tree().get_nodes_in_group("cajas"):
			var sincronizador := caja.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
			if sincronizador:
				sincronizador.public_visibility = false

	# Esperar a que todos los clientes tengan creado su Level2/MultiplayerSpawner.
	if not multiplayer.has_multiplayer_peer():
		spawning_player(1)
	elif multiplayer.is_server():
		jugadores_listos[1] = true
		_intentar_spawn.call_deferred()
	else:
		_nivel_listo.rpc_id(1)

@rpc("any_peer", "reliable")
func _nivel_listo() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	jugadores_listos[peer_id] = true
	for caja in get_tree().get_nodes_in_group("cajas"):
		var sincronizador := caja.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
		if sincronizador:
			sincronizador.set_visibility_for(peer_id, true)
	_intentar_spawn()


func _intentar_spawn() -> void:
	if spawn_realizado:
		return
	for peer_id in multiplayer.get_peers():
		if not jugadores_listos.has(peer_id):
			return

	spawn_realizado = true
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
