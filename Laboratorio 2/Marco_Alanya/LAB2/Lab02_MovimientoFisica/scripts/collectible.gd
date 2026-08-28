extends Area2D

signal collected(points: int)

@export var points: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit(points)
		queue_free()
