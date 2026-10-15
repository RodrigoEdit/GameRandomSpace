extends Area2D

# --- PARÁMETROS FÍSICOS Y MATEMÁTICOS ---
@export var velocidad_lineal: float = 220.0   # MRU: Velocidad de avance (px/s)
@export var velocidad_angular: float = 12.0   # MCU (ω): Velocidad de giro (radianes/s)
@export var radio_giro: float = 35.0          # Amplitud / Radio del círculo (R)
@export var modo_espiral: bool = false        # false = avanza en círculos | true = espiral expansiva

var tiempo: float = 0.0
var posicion_inicial: Vector2
var direccion_x: float = 1.0 # 1 derecha, -1 izquierda
var angulo_inicial: float = 0.0

func _ready() -> void:
	posicion_inicial = global_position
	# Destruir el proyectil después de 3 segundos para no saturar memoria
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	tiempo += delta
	var angulo_actual: float = angulo_inicial + (velocidad_angular * tiempo)
	
	if modo_espiral:
		# FÓRMULA 1: Espiral de Arquímedes r(t) = v_r * t
		# El radio crece linealmente con el tiempo mientras rota con cos(ωt) y sin(ωt)
		var radio_actual: float = 90.0 * tiempo
		var offset_x: float = radio_actual * cos(angulo_actual)
		var offset_y: float = radio_actual * sin(angulo_actual)
		global_position = posicion_inicial + Vector2(offset_x, offset_y)
	else:
		# FÓRMULA 2: Movimiento Trocoide / Helicoidal 2D (MRU + MCU)
		# Avance rectilíneo en X + oscilación circular armónica con Seno y Coseno
		var avance_mru: float = velocidad_lineal * tiempo * direccion_x
		var circulo_x: float = radio_giro * cos(angulo_actual)
		var circulo_y: float = radio_giro * sin(angulo_actual)
		global_position = posicion_inicial + Vector2(avance_mru + circulo_x, circulo_y)
