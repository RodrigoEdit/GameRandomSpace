@tool
extends RigidBody2D
class_name Caja

const TEXTURAS = {
	"puma": preload("res://Sprites/puma.png"),
	"sol": preload("res://Sprites/sol.png"),
	"condor": preload("res://Sprites/condor.png"),
	"serpiente": preload("res://Sprites/serpiente.png")
}

@export var id_caja: String = "sol":
	set(nuevo_valor):
		id_caja = nuevo_valor.to_lower()
		actualizar_imagen()

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready() -> void:
	actualizar_imagen()

func actualizar_imagen() -> void:
	if is_node_ready() and sprite_2d and id_caja in TEXTURAS:
		sprite_2d.texture = TEXTURAS[id_caja]
