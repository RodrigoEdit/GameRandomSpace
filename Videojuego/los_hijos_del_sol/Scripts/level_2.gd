extends Node2D

var sellos_activados: int = 0
const TOTAL_SELLOS: int = 4

# Referencia al nodo de la puerta
@onready var puerta: Puerta = $Puerta

# Ajusta esta ruta a tu nodo de colisión de la puerta
@onready var colision_puerta: CollisionShape2D = $PuertaSellada/CollisionShape2D

func _ready() -> void:
	# Detecta automáticamente todas las placas agregadas al grupo "placas"
	for placa in get_tree().get_nodes_in_group("placas"):
		placa.placa_activada.connect(_on_placa_activada)
		placa.placa_desactivada.connect(_on_placa_desactivada)

func _on_placa_activada(tipo: String) -> void:
	sellos_activados += 1
	print("Sello correcto encajado: ", tipo, ". Total: ", sellos_activados, "/4")
	_verificar_puerta()

func _on_placa_desactivada(tipo: String) -> void:
	sellos_activados = max(0, sellos_activados - 1)
	print("Caja retirada de la placa: ", tipo, ". Total: ", sellos_activados, "/4")

func _verificar_puerta() -> void:
	if sellos_activados >= TOTAL_SELLOS:
		puerta.abrir_puerta()

func abrir_puerta() -> void:
	print("¡Los 4 sellos están activados! Desbloqueando paso.")
	if colision_puerta:
		colision_puerta.set_deferred("disabled", true)
	# Opcional: Oculta el gráfico de la puerta sellada o activa una animación
	if has_node("PuertaSellada"):
		$PuertaSellada.hide()
