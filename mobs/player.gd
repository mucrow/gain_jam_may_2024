extends CharacterBody2D
class_name Player


@export var jump_velocity = -500.0
@export var move_speed_in_air = 50.0
@export var move_speed_on_floor = 300.0
@export var max_run_speed = 300.0
@export var deceleration_floor = 300.0
@export var deceleration_air = 0.0
@export var gravity = 980.0
@export var walljump_strength = 400
@export var walljump_max_distance = 30
@export var dash_velocity = 800.0
@export var max_speed = 1100.0

@export var walljump_lockin_time = 0.3



enum State {
  Free, Launched
}

@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var launched_state_timer: Timer = $LaunchedStateTimer
@onready var sprite: AnimatedSprite2D = $Sprite

var state = State.Free

var in_dash_cooldown: bool = false
var walltouch_velocity: Vector2
var justtouchedwall: bool = false


func _physics_process(dt):
  if state == State.Free:
    state_free_physics_process(dt)
  elif state == State.Launched:
    state_launched_physics_process(dt)
  else:
    push_warning('unhandled state %s' % state)
    state = State.Free


func state_free_physics_process(dt):
  check_walltouch()

  apply_gravity(dt)

  var direction = Input.get_axis("move_left", "move_right")
  direction = sign(direction)

  var move_speed = move_speed_on_floor if is_on_floor() else move_speed_in_air
  var current_max_speed = max_run_speed
  if abs(sign(velocity.x) - direction) < 0.0001:
    current_max_speed = max(abs(velocity.x), max_run_speed)
  current_max_speed = min(current_max_speed, max_speed)
  if direction:
    velocity.x = move_toward(velocity.x, direction * current_max_speed, move_speed)
  elif is_on_floor() or (abs(velocity.x) <= max_run_speed): #do an input in the air to decelerate slower
    velocity.x = move_toward(velocity.x, 0, deceleration_floor)
  else: #eternally applied air deceleration
    velocity.x = move_toward(velocity.x, 0, deceleration_air)

  if Input.is_action_just_pressed("jump"):
    if is_on_floor():
      velocity.y = jump_velocity
    else:
      var canwalljump = can_walljump()
      if canwalljump:
        apply_walljump(canwalljump)

  if Input.is_action_just_pressed("dash") and not in_dash_cooldown:
    if direction != 0:
      apply_dash(direction)
    else:
      apply_dash(-1.0 if sprite.flip_h else 1.0)

  move_and_slide()

  if in_dash_cooldown:
    pass
  elif abs(velocity.x) < 0.1:
    sprite.animation = 'Idle'
    sprite.play()
  else:
    sprite.flip_h = velocity.x < 0.0
    sprite.animation = 'Run'
    sprite.play()

  for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
    if collider.is_in_group('enemies'):
      if collider.has_method('on_collision_with_player'):
        collider.on_collision_with_player(self)


func state_launched_physics_process(dt):
  check_walltouch()

  apply_gravity(dt)

  var direction = Input.get_axis("move_left", "move_right")
  direction = sign(direction)

  if Input.is_action_just_pressed("dash") and not in_dash_cooldown:
    if direction != 0:
      apply_dash(direction)
    else:
      apply_dash(-1.0 if sprite.flip_h else 1.0)

  if Input.is_action_just_pressed("jump"):
    var canwalljump = can_walljump()
    if canwalljump:
      apply_walljump(canwalljump)

  move_and_slide()


func apply_gravity(dt):
  if not is_on_floor() and not in_dash_cooldown:
    velocity.y += gravity * dt


func check_walltouch():
  if not justtouchedwall and is_on_wall_only():
    justtouchedwall = true
    walltouch_velocity = get_last_slide_collision().get_travel() * 400 + get_last_slide_collision().get_remainder() * 400
    # print("storing wallhit velocity")
    # print(walltouch_velocity)

  if not is_on_wall_only():
    justtouchedwall = false


func apply_launch(new_velocity: Vector2, duration: float):
  velocity = new_velocity
  if duration > 0.0001:
    sprite.modulate = Color(1, 0.25, 0.25)
    state = State.Launched
    launched_state_timer.wait_time = duration
    launched_state_timer.start()


func apply_dash(direction: float):
  sprite.flip_h = direction < 0.0
  sprite.animation = 'Dash'
  sprite.play()
  velocity.y = 0.0
  if abs(velocity.x) < dash_velocity: velocity.x = direction * dash_velocity
  in_dash_cooldown = true
  dash_cooldown_timer.start()


func restore_dash():
  in_dash_cooldown = false


func end_launched_state():
  sprite.modulate = Color.WHITE
  state = State.Free


# returns -1 if can walljump off left wall, 1 if off right wall, 0 if can't walljump
func can_walljump():
    var space_state = get_world_2d().direct_space_state
    var left_query = PhysicsRayQueryParameters2D.create(position, position - Vector2(walljump_max_distance, 0))
    left_query.exclude = [self]
    var left_result = space_state.intersect_ray(left_query)
    if left_result:
      var collider = left_result["collider"]
      if collider.is_in_group("wall"):
        return -1

    var right_query = PhysicsRayQueryParameters2D.create(position, position + Vector2(walljump_max_distance, 0))
    right_query.exclude = [self]
    var right_result = space_state.intersect_ray(right_query)
    if right_result:
      var collider = right_result["collider"]
      if collider.is_in_group("wall"):
        return 1

    return 0


func apply_walljump(dir):
    var min_launch_velocity = (dir * Vector2.LEFT + Vector2.UP) * walljump_strength
    var launch_velocity = min_launch_velocity
    velocity.y = 0

    apply_launch(launch_velocity, walljump_lockin_time)
    walltouch_velocity = Vector2.ZERO
