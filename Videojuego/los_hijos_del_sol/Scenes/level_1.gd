extends Node2D

const PORT: int = 7000

# Cargamos las escenas por separado
const PLAYER_ONE_SCENE = preload("res://Scenes/player_one.tscn")
const PLAYER_TWO_SCENE = preload("res://Scenes/player_two.tscn")

@onready var lobby_ui: CanvasLayer = $LobbyUI
@onready var input_ip: LineEdit = $LobbyUI/InputIP

func _ready() -> void:
	MusicManager.play_level(1)
	$LobbyUI/BtnHost.pressed.connect(crear_servidor)
	$LobbyUI/BtnJoin.pressed.connect(unirse_a_partida)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Botón HOST
func crear_servidor() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("Error al iniciar el servidor: ", error)
		DebugLogger.log_error("Error al iniciar servidor: %s" % error)
		return
	
	multiplayer.multiplayer_peer = peer
	
	# Eventos de red (solo el Host gestiona el ciclo de vida de los jugadores)
	multiplayer.peer_connected.connect(spawning_player)
	multiplayer.peer_disconnected.connect(eliminar_jugador)
	
	lobby_ui.hide()
	
	# Instanciar a María (Host = ID 1)
	spawning_player(1)
	print("Servidor iniciado en el puerto ", PORT)
	DebugLogger.log_info("Servidor iniciado en puerto %d" % PORT)

# Botón CLIENTE
func unirse_a_partida() -> void:
	var peer = ENetMultiplayerPeer.new()
	var ip = input_ip.text.strip_edges()
	
	if ip == "":
		ip = "127.0.0.1"
		
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Error al conectar con la IP: ", error)
		DebugLogger.log_error("Error creando cliente para %s:%d: %s" % [ip, PORT, error])
		return
		
	multiplayer.multiplayer_peer = peer
	print("Intentando conectar con ", ip, ":", PORT)
	DebugLogger.log_info("Intentando conectar con %s:%d" % [ip, PORT])


func _on_connected_to_server() -> void:
	lobby_ui.hide()
	print("Conectado al servidor. ID local: ", multiplayer.get_unique_id())
	DebugLogger.log_info("Conectado al servidor. ID local: %d" % multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	lobby_ui.show()
	multiplayer.multiplayer_peer = null
	push_error("No se pudo conectar al servidor. Revisa la IP, el puerto 7000 y el firewall.")
	DebugLogger.log_error("Conexión fallida: revisa IP, puerto 7000 y firewall")


func _on_server_disconnected() -> void:
	lobby_ui.show()
	push_error("El servidor se desconectó.")
	DebugLogger.log_error("El servidor se desconectó")


func cambiar_a_nivel_2() -> void:
	var ruta := "res://Scenes/level2.tscn"

	if not multiplayer.has_multiplayer_peer():
		Transicion.cambiar_nivel(ruta)
		return

	if multiplayer.is_server():
		# El RPC se ejecuta en el host y en todos los clientes.
		Transicion.cambiar_nivel.rpc(ruta)

# Instanciar personaje (Solo corre en el Host)
func spawning_player(id: int) -> void:
	if $spawn.get_node_or_null(str(id)):
		return
	var player: Node2D
	
	if id == 1:
		player = PLAYER_ONE_SCENE.instantiate()
	else:
		player = PLAYER_TWO_SCENE.instantiate()
		
	# 1. Asignar el ID como nombre de nodo antes de entrar al árbol
	player.name = str(id)
	
	# 2. Agregar como hijo forzando que mantenga el nombre exacto
	$spawn.add_child(player, true)
	
	# 3. Asignar posición
	if id == 1:
		player.global_position = $spawn.global_position
	else:
		player.global_position = $spawn.global_position + Vector2(25, 0)


func respawn_player(id: int) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	var viejo := $spawn.get_node_or_null(str(id))
	if viejo:
		viejo.queue_free()
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		spawning_player(id)

# Cuando alguien se sale de la partida
func eliminar_jugador(id: int) -> void:
	var player = $spawn.get_node_or_null(str(id))
	if player:
		player.queue_free()
