extends CharacterBody2D
class_name Bungus


enum State {
  Free, Launched
}

@export var move_acceleration = 30.0
@export var move_speed = 100.0
@export var gravity = 980.0

@onready var launched_state_timer: Timer = $LaunchedStateTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction = -1.0
var previous_velocity = Vector2.ZERO
var state = State.Free


func _physics_process(dt):
  if state == State.Free:
    state_free_physics_process(dt)
  elif state == State.Launched:
    state_launched_physics_process(dt)
  else:
    push_warning('unhandled BUNGUS state %s' % state)
    state = State.Free
  previous_velocity = velocity


func state_free_physics_process(dt):
  if is_on_floor():
    velocity.y = 0
  else:
    velocity.y += gravity * dt

  velocity.x = move_toward(velocity.x, direction * move_speed, move_acceleration)
  move_and_slide()


func state_launched_physics_process(dt):
  if not is_on_floor():
    velocity.y += gravity * dt

  move_and_slide()

  if is_on_wall():
    var normal = get_wall_normal()
    velocity = previous_velocity.bounce(normal)


func apply_launched_state(new_velocity: Vector2, duration: float):
  velocity = new_velocity
  if duration > 0.0001:
    state = State.Launched
    launched_state_timer.wait_time = duration
    launched_state_timer.start()


func end_launched_state():
  launched_state_timer.stop()
  state = State.Free


func on_turnaround_timeout():
  direction *= -1.0
  sprite.flip_h = not sprite.flip_h


func on_collision_with_player(player: Player):
  var player_speed = player.previous_velocity.length()
  var launch_velocity = (position - player.position).normalized() * player_speed
  player.velocity = Vector2.ZERO
  if is_on_floor() and launch_velocity.y > 0.0:
    launch_velocity.y *= -1.0
  apply_launched_state(launch_velocity, player_speed / 1100.0)
