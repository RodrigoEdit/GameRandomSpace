
extends RigidBody2D
class_name Caja

const TEXTURAS = {
	"puma": preload("res://Sprites/puma.png"),
	"sol": preload("res://Sprites/sol.png"),
	"condor": preload("res://Sprites/condor.png"),
	"serpiente": preload("res://Sprites/serpiente.png")
}

# Solo limita la aceleración hacia abajo. Las otras direcciones conservan
# exactamente el comportamiento actual.
const VELOCIDAD_MAXIMA_HACIA_ABAJO := 110.0

@export var id_caja: String = "sol":
	set(nuevo_valor):
		id_caja = nuevo_valor.to_lower()
		actualizar_imagen()

@onready var sprite_2d: Sprite2D = $Sprite2D

# NUEVO: Sonido de arrastre
@onready var sonido: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _enter_tree() -> void:
	# El servidor es la única autoridad de la física de las cajas.
	set_multiplayer_authority(1)

func _ready() -> void:
	actualizar_imagen()
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		# El cliente recibe posición/velocidad por MultiplayerSynchronizer;
		# no debe simular otra física en paralelo.
		freeze = true

func actualizar_imagen() -> void:
	if is_node_ready() and sprite_2d and id_caja in TEXTURAS:
		sprite_2d.texture = TEXTURAS[id_caja]


@rpc("any_peer", "unreliable")
func empujar(impulso: Vector2) -> void:
	# La física de las cajas la decide el servidor.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	apply_central_impulse(impulso)
	if linear_velocity.y > VELOCIDAD_MAXIMA_HACIA_ABAJO:
		linear_velocity.y = VELOCIDAD_MAXIMA_HACIA_ABAJO


# NUEVO: Detectar movimiento de la caja
func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > 10.0:
		if not sonido.playing:
			sonido.play()
	else:
		if sonido.playing:
			sonido.stop()
