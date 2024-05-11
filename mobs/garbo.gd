extends CharacterBody2D


# bugs don't jump and gods don't bleed
@export var jump_velocity = -400.0
@export var move_speed = 100.0
@export var gravity = 980.0

@export var launch_speed = 900.0
@export var launch_strength_x: float = 1
@export var launch_strength_y: float = 0.6

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction = -1.0


func _physics_process(delta):
  if not is_on_floor():
    velocity.y += gravity * delta

  velocity.x = direction * move_speed
  move_and_slide()


func on_turnaround_timeout():
  direction *= -1.0
  sprite.flip_h = not sprite.flip_h


func on_collision_with_player(player: Player):
  var launch_velocity = (player.position - position).normalized() * launch_speed
  launch_velocity = (launch_velocity.dot(Vector2.RIGHT) * launch_strength_x * Vector2.RIGHT) + (launch_velocity.dot(Vector2.UP) * launch_strength_y * Vector2.UP)
  player.apply_launch(launch_velocity, 0.4, true)
