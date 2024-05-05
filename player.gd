extends CharacterBody2D


@export var jump_velocity = -400.0
@export var move_speed = 300.0
@export var gravity = 980.0


func _physics_process(delta):
  # Add the gravity.
  if not is_on_floor():
    velocity.y += gravity * delta

  # Handle jump.
  if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = jump_velocity

  # Get the input direction and handle the movement/deceleration.
  var direction = Input.get_axis("move_left", "move_right")
  if direction:
    velocity.x = direction * move_speed
  else:
    velocity.x = move_toward(velocity.x, 0, move_speed)

  move_and_slide()
