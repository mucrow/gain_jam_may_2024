extends CharacterBody2D


# bugs don't jump and gods don't bleed
@export var jump_velocity = -400.0
@export var move_speed = 100.0
@export var gravity = 980.0

var direction = -1.0


func _physics_process(delta):
  if not is_on_floor():
    velocity.y += gravity * delta

  velocity.x = direction * move_speed
  move_and_slide()
  


func on_turnaround_timeout():
  direction *= -1.0
  var sprite = $CollisionShape2D/AnimatedSprite2D
  sprite.flip_h = not sprite.flip_h
