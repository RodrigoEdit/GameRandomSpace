extends CharacterBody2D

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
		update_animation(true)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		update_animation(false)

	move_and_slide()

func update_animation(is_moving: bool) -> void:
	var dir_suffix := get_direction_suffix(facing_direction)
	var prefix := "walk_" if is_moving else "idle_"
	var anim_name := prefix + dir_suffix

	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func get_direction_suffix(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"
