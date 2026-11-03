extends Node2D

const PORT: int = 7000

# 1. Cargamos las dos escenas por separado
const PLAYER_ONE_SCENE = preload("res://Scenes/player_one.tscn")
const PLAYER_TWO_SCENE = preload("res://Scenes/player_two.tscn")

@onready var lobby_ui: CanvasLayer = $LobbyUI
@onready var input_ip: LineEdit = $LobbyUI/InputIP

func _ready() -> void:
	$LobbyUI/BtnHost.pressed.connect(crear_servidor)
	$LobbyUI/BtnJoin.pressed.connect(unirse_a_partida)

# Botón HOST
func crear_servidor() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("Error al iniciar el servidor: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Conexión y desconexión de clientes
	multiplayer.peer_connected.connect(spawning_player)
	multiplayer.peer_disconnected.connect(eliminar_jugador)
	
	lobby_ui.hide()
	
	# El host siempre es el ID 1 (Player 1)
	spawning_player(1)

# Botón CLIENTE
func unirse_a_partida() -> void:
	var peer = ENetMultiplayerPeer.new()
	var ip = input_ip.text.strip_edges()
	
	if ip == "":
		ip = "127.0.0.1"
		
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Error al conectar con la IP: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	lobby_ui.hide()

# Instanciar personajes en el Host (el MultiplayerSpawner los replica solo a las otras PCs)
func spawning_player(id: int) -> void:
	var player: Node2D
	
	if id == 1:
		player = PLAYER_ONE_SCENE.instantiate()
	else:
		player = PLAYER_TWO_SCENE.instantiate()
		
	# 1. Asignar el nombre obligatorio para la red
	player.name = str(id)
	
	# 2. PRIMERO se añade al árbol
	$spawn.add_child(player)
	
	# 3. DESPUÉS se le da la posición exacta
	if id == 1:
		player.global_position = $spawn.global_position
	else:
		player.global_position = $spawn.global_position + Vector2(25, 0)

# Si el compañero se desconecta o cierra la ventana
func eliminar_jugador(id: int) -> void:
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
