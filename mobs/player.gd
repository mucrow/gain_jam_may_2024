extends CharacterBody2D
class_name Player


@export var jump_velocity = -500.0
@export var move_speed_in_air = 50.0
@export var move_speed_on_floor = 300.0
@export var max_speed = 300
@export var deceleration_floor = 300.0
@export var deceleration_air = 0.0
@export var gravity = 980.0
@export var walljump_strength = 400
@export var walljump_max_distance = 30


enum State {
  Free, Launched
}

@onready var launched_state_timer: Timer = $LaunchedStateTimer
@onready var sprite: AnimatedSprite2D = $Sprite

var state = State.Free

var walltouch_velocity: Vector2
var justtouchedwall: bool = false


func _physics_process(dt):
  if not justtouchedwall and is_on_wall_only():
    justtouchedwall = true
    walltouch_velocity = get_last_slide_collision().get_travel() * 400 + get_last_slide_collision().get_remainder() * 400
    print("storing wallhit velocity")
    print(walltouch_velocity)

  if not is_on_wall_only():
    justtouchedwall = false

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

  if Input.is_action_just_pressed("jump"):
    if is_on_floor():
      velocity.y = jump_velocity
    else:
      var canwalljump = can_walljump()
      if canwalljump:
        apply_walljump(canwalljump)

  var direction = Input.get_axis("move_left", "move_right")
  direction = sign(direction)
  var move_speed = move_speed_on_floor if is_on_floor() else move_speed_in_air
  if direction:
    velocity.x = move_toward(velocity.x, direction * max_speed, move_speed)
  elif is_on_floor() or (abs(velocity.x) <= max_speed): #do an input in the air to decelerate slower
    velocity.x = move_toward(velocity.x, 0, deceleration_floor)
  else: #eternally applied air deceleration
    velocity.x = move_toward(velocity.x, 0, deceleration_air)

  move_and_slide()

  if abs(velocity.x) < 0.1:
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
  if not is_on_floor():
    velocity.y += gravity * dt

  if Input.is_action_just_pressed("jump"):
    var canwalljump = can_walljump()
    if canwalljump:
      apply_walljump(canwalljump)

  move_and_slide()


func apply_launched_state(new_velocity: Vector2, duration: float):
  velocity = new_velocity
  state = State.Launched
  launched_state_timer.wait_time = duration
  launched_state_timer.start()


func end_launched_state():
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

    apply_launched_state(launch_velocity, 0.4)
    walltouch_velocity = Vector2.ZERO
