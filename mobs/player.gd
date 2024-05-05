extends CharacterBody2D


@export var jump_velocity = -500.0
@export var move_speed_in_air = 100.0
@export var move_speed_on_floor = 300.0
@export var gravity = 980.0

@export var launch_strength_x: float = 1
@export var launch_strength_y: float = 1


enum State {
  Free, Launched
}

@onready var launched_state_timer: Timer = $LaunchedStateTimer
@onready var sprite: AnimatedSprite2D = $Sprite

var state = State.Free


func _physics_process(dt):
  if state == State.Free:
    state_free_physics_process(dt)
  elif state == State.Launched:
    state_launched_physics_process(dt)
  else:
    push_warning('unhandled state %s' % state)
    state = State.Free


func state_free_physics_process(dt):
  if not is_on_floor():
    velocity.y += gravity * dt

  if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = jump_velocity

  var direction = Input.get_axis("move_left", "move_right")
  var move_speed = move_speed_on_floor if is_on_floor() else move_speed_in_air
  if direction:
    velocity.x = move_toward(velocity.x, direction * move_speed_on_floor, move_speed)
  else:
    velocity.x = move_toward(velocity.x, 0, move_speed)

  move_and_slide()

  if abs(velocity.x) < 0.1:
    sprite.animation = 'Idle'
    sprite.play()
  else:
    sprite.flip_h = velocity.x < 0.0
    sprite.animation = 'Run'
    sprite.play()

  # TODO let enemies handle this
  for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
    if collider.is_in_group('enemies'):
      var launch_velocity = (position - collider.position).normalized() * 900.0
      launch_velocity = (launch_velocity.dot(Vector2.RIGHT) * launch_strength_x * Vector2.RIGHT) + (launch_velocity.dot(Vector2.UP) * launch_strength_y * Vector2.UP)
      apply_launched_state(launch_velocity, 0.5)


func state_launched_physics_process(dt):
  if not is_on_floor():
    velocity.y += gravity * dt
  move_and_slide()


func apply_launched_state(new_velocity: Vector2, duration: float):
  velocity = new_velocity
  state = State.Launched
  launched_state_timer.wait_time = duration
  launched_state_timer.start()


func end_launched_state():
  state = State.Free
