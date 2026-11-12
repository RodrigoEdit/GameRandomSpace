extends StaticBody2D
class_name Puerta

@onready var color_rect: ColorRect = $ColorRect
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sonido_apertura: AudioStreamPlayer2D = $SonidoApertura
@onready var particulas_apertura: CPUParticles2D = $ParticulasApertura

# Ruta de la escena del siguiente nivel al que pasará el jugador
@export_file("*.tscn") var siguiente_nivel: String

func _ready() -> void:
	# El recuadro comienza completamente transparente (alpha = 0.0)
	color_rect.color.a = 0.0

func abrir_puerta() -> void:
	if sonido_apertura:
		sonido_apertura.play()
	if particulas_apertura:
		particulas_apertura.emitting = true
	print("Abriendo puerta mágicamente...")
	
	# 1. Desactivamos la colisión física para permitir el paso inmediatamente o al finalizar
	colision.set_deferred("disabled", true)
	
	# 2. Animación progresiva (Tween) del color transparente a negro sólido (alpha = 1.0)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 1.5) # Dura 1.5 segundos
