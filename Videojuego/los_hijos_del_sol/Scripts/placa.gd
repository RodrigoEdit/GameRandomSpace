@tool
extends Area2D
class_name Placa

signal placa_activada(tipo: String)
signal placa_desactivada(tipo: String)

# Asigna las imágenes separadas para cada tipo de placa
const TEXTURAS = {
	"puma": preload("res://Sprites/placa_pantera.png"),
	"sol": preload("res://Sprites/placa_sol.png"),
	"condor": preload("res://Sprites/placa_condor.png"),
	"serpiente": preload("res://Sprites/placa_serpiente.png")
}

@export var tipo_requerido: String = "sol":
	set(nuevo_valor):
		tipo_requerido = nuevo_valor.to_lower()
		actualizar_imagen()

var esta_activada: bool = false
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	actualizar_imagen()
	
	# Las señales de colisión solo se conectan durante el juego
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func actualizar_imagen() -> void:
	if is_node_ready() and sprite_2d and tipo_requerido in TEXTURAS:
		sprite_2d.texture = TEXTURAS[tipo_requerido]

func _on_body_entered(body: Node2D) -> void:
	if body is Caja and body.id_caja == tipo_requerido:
		esta_activada = true
		placa_activada.emit(tipo_requerido)

func _on_body_exited(body: Node2D) -> void:
	if body is Caja and body.id_caja == tipo_requerido:
		esta_activada = false
		placa_desactivada.emit(tipo_requerido)
