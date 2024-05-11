extends CharacterBody2D
class_name Player


@export var jump_velocity = -500.0
@export var move_accel_in_air = 50.0
@export var move_accel_on_floor = 300.0
@export var max_run_speed = 300.0

@export var frictionloss_floor = 0.9

@export var decel_floor = 300.0
@export var decel_floor_launched = 20
@export var decel_air = 0.0
@export var gravity = 980.0
@export var walljump_strength = 400
@export var walljump_max_distance = 30
@export var dash_velocity = 800.0
@export var max_speed = 1100.0

@export var walljump_lockin_time = 0.3
@export var dash_lockin_time = 0.3



enum State {
  Free, Launched, Dash
}

@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var launched_state_timer: Timer = $LaunchedStateTimer
@onready var sprite: AnimatedSprite2D = $Sprite

var state = State.Free

var is_stunned = false

var walltouch_velocity: Vector2
var justtouchedwall: bool = false

var previous_velocity: Vector2


func _ready():
  dash_cooldown_timer.timeout.connect(end_dash_state)
  sprite.animation_finished.connect(end_animation)
  pass #pass away

func _physics_process(dt):
  if state == State.Free:
    state_free_physics_process(dt)
  elif state == State.Launched:
    state_launched_physics_process(dt)
  elif state == State.Dash:
    state_dash_physics_process(dt)
  else:
    push_warning('unhandled state %s' % state)
    state = State.Free 
  previous_velocity = velocity


######################################################################################
# STATE PHYSICS PROESESCSES
######################################################################################
func state_free_physics_process(dt):
  check_walltouch()

  apply_gravity(dt)

  var direction = Input.get_axis("move_left", "move_right")
  direction = sign(direction)
  var canwalljump = can_walljump()

  #current max speed represents how fast you go if you hold in one direction.
  #if you're in the air, your current max speed is either max_speed or your own speed; if you're going faster than max speed, you can continue to go faster by holding direction.
  #if you're on the ground, same deal, but slight friction applies. you will steadily lose speed back to your regular run speed unless you dash again, jump, something else

  var move_speed = move_accel_on_floor if is_on_floor() else move_accel_in_air
  var current_max_speed = max_run_speed
  if abs(sign(velocity.x) - direction) < 0.0001:
    var eff_xvelocity = abs(velocity.x)
    if is_on_floor(): eff_xvelocity *= frictionloss_floor
    current_max_speed = max(eff_xvelocity, max_run_speed)
  current_max_speed = min(current_max_speed, max_speed)

  if direction:
    velocity.x = move_toward(velocity.x, direction * current_max_speed, move_speed)
  elif is_on_floor() or (abs(velocity.x) <= max_run_speed): #do an input in the air to decelerate slower
    velocity.x = move_toward(velocity.x, 0, decel_floor)
  else: #eternally applied air deceleration
    velocity.x = move_toward(velocity.x, 0, decel_air)

  if Input.is_action_just_pressed("jump"):
    if is_on_floor():
      velocity.y = jump_velocity
      sprite.animation = "JumpStart"
    else:
      if canwalljump:
        apply_walljump(canwalljump)

  if Input.is_action_just_pressed("dash"):
    if direction != 0:
      apply_dash(direction)
    else:
      apply_dash(-1.0 if sprite.flip_h else 1.0)

  move_and_slide()

  if not is_on_floor() and canwalljump:
    sprite.flip_h = true if canwalljump == 1 else false
    sprite.animation = "Wallslide"
    sprite.play()
  elif not is_on_floor() and not (sprite.animation == "Jump" or sprite.animation == "JumpStart"):
    sprite.animation = "Jump"
    sprite.play()
  elif is_on_floor() and abs(velocity.x) >= 0.1:
    sprite.flip_h = velocity.x < 0.0
    sprite.animation = 'Run'
    sprite.play()
  elif is_on_floor() and sprite.animation != 'IdleStart' and sprite.animation != 'Idle':
    sprite.animation = 'IdleStart'
    sprite.play()

  check_enemy_collision()


func state_launched_physics_process(dt):
  check_walltouch()

  apply_gravity(dt)

  var direction = Input.get_axis("move_left", "move_right")
  direction = sign(direction)

  if not is_stunned and Input.is_action_just_pressed("dash"):
    end_launched_state()
    if direction != 0:
      apply_dash(direction)
    else:
      apply_dash(-1.0 if sprite.flip_h else 1.0)

  if not is_stunned and Input.is_action_just_pressed("jump"):
    var canwalljump = can_walljump()
    if is_on_floor():
      velocity.y = jump_velocity
      sprite.animation = "JumpStart"
      end_launched_state()
    elif canwalljump:
      end_launched_state()
      apply_walljump(canwalljump)
      
  if is_on_floor():
    velocity.x = move_toward(velocity.x, 0, decel_floor_launched)

  move_and_slide()

  if is_stunned and sprite.animation != "Stun":
    sprite.animation = "Stun"
    sprite.play()
  elif not is_stunned and sprite.animation != "Dash":
    sprite.animation = "Dash"
    sprite.flip_h = true if velocity.x < 0 else false
    sprite.play()

  check_enemy_collision()


func state_dash_physics_process(dt):
  check_walltouch()
  
  sprite.animation = 'Dash'
  sprite.play()

  if Input.is_action_just_pressed("jump"):
    var canwalljump = can_walljump()
    if is_on_floor():
      velocity.y = jump_velocity
      end_dash_state()
    elif canwalljump:
      end_dash_state()
      apply_walljump(canwalljump)

  move_and_slide()

  check_enemy_collision()


######################################################################################
# CHECK ABILITES/state
######################################################################################

func check_walltouch():
  var canwal = can_walljump()
  if not justtouchedwall and canwal:
    justtouchedwall = true
    #TODO: remove walltouch velocity if you leave the wall (or 1 sec until it disappears?)
    walltouch_velocity = previous_velocity
    print("storing wallhit velocity")
    print(walltouch_velocity)

  if not can_walljump():
    justtouchedwall = false


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

func check_enemy_collision():
  for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
    if collider.is_in_group('enemies'):
      if collider.has_method('on_collision_with_player'):
        collider.on_collision_with_player(self)


######################################################################################
# APPLY/END STATES
######################################################################################

func apply_gravity(dt):
  if not is_on_floor():
    velocity.y += gravity * dt


func apply_launch(new_velocity: Vector2, duration: float, is_stunning_launch: bool = false):
  is_stunned = is_stunning_launch
  #clean up previous state
  dash_cooldown_timer.stop()
  #... whatever other state

  velocity = new_velocity
  if duration > 0.0001:
    sprite.modulate = Color(1, 0.25, 0.25)
    state = State.Launched
    launched_state_timer.wait_time = duration
    launched_state_timer.start()


func apply_dash(direction: float):
  state = State.Dash

  sprite.flip_h = direction < 0.0
  sprite.animation = 'Dash'
  sprite.play()
  var new_velocity = Vector2(velocity.x, 0)
  if abs(velocity.x) < dash_velocity: new_velocity.x = direction * dash_velocity

  velocity = new_velocity
  dash_cooldown_timer.wait_time = dash_lockin_time
  dash_cooldown_timer.start()


func apply_walljump(dir):
    var min_launch_velocity = (dir * Vector2.LEFT + Vector2.UP) * walljump_strength
    var launch_velocity = min_launch_velocity
    if abs(walltouch_velocity.x) > abs(launch_velocity.x):
      launch_velocity.x = -walltouch_velocity.x 
    velocity.y = 0

    apply_launch(launch_velocity, walljump_lockin_time)
    walltouch_velocity = Vector2.ZERO




func end_launched_state():
  sprite.modulate = Color.WHITE
  launched_state_timer.stop()
  state = State.Free

func end_dash_state():
  dash_cooldown_timer.stop()
  state = State.Free
  
func end_animation():
  if sprite.animation == "IdleStart":
    sprite.animation = "Idle"
    sprite.play()
  elif sprite.animation == "JumpStart":
    sprite.animation = "Jump"
    sprite.play()
