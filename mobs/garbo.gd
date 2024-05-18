extends CharacterBody2D
class_name Garbo


@export var move_speed = 100.0
@export var gravity = 980.0

@export var launch_speed = 900.0
@export var launch_strength_x: float = 1
@export var launch_strength_y: float = 0.6

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $SpriteAnchor/AnimatedSprite2D
@onready var sprite_anchor: Node2D = $SpriteAnchor
@onready var stack_point: Node2D = $SpriteAnchor/StackPoint
@onready var turnaround_timer: Timer = $TurnaroundTimer

var direction = -1.0
var sprite_height = 0
var stacked_garbo_a_scene = preload('res://mobs/stacked_garbo_a.tscn')
var stacked_garbo_b_scene = preload('res://mobs/stacked_garbo_b.tscn')
var stacked_objects = []


func _ready():
  sprite_height = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_height()


func _physics_process(dt):
  if not is_on_floor():
    velocity.y += gravity * dt
  velocity.x = move_toward(velocity.x, direction * move_speed, 30.0)
  move_and_slide()

  for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var normal = collision.get_normal()
    var other_collider = collision.get_collider()
    if other_collider.is_in_group('bunguses'):
      on_collision_with_bungus(other_collider, normal)
    elif other_collider.is_in_group('garbos'):
      on_collision_with_other_garbo(other_collider)


func on_turnaround_timeout():
  direction *= -1.0
  sprite.flip_h = not sprite.flip_h
  for stacked_garbo in stacked_objects:
    stacked_garbo.toggle_sprite_flip_h()


func on_collision_with_bungus(bungus: Bungus, normal: Vector2):
  if bungus.state == Bungus.State.Launched:
    bungus.velocity = bungus.previous_velocity.bounce(normal)
  else:
    var launch_velocity = normal * 1000.0
    print(launch_velocity)
    bungus.apply_launched_state(launch_velocity, 0.3)


func on_collision_with_other_garbo(other: Garbo):
  var stack_check_point = get_stack_check_point()
  var angle_to_other = rad_to_deg(((other.position - stack_check_point).angle()))
  if angle_to_other >= -135.0 and angle_to_other < -45.0:
    stack_garbo(other)
  elif angle_to_other >= -45.0 and angle_to_other < 45.0:
    turnaround_timer.stop()
    turnaround_timer.start()
    on_turnaround_timeout()
    other.on_turnaround_timeout()


func on_collision_with_player(player: Player):
  var true_center = get_true_center()
  var launch_velocity = (player.position - true_center).normalized() * launch_speed
  launch_velocity = (launch_velocity.dot(Vector2.RIGHT) * launch_strength_x * Vector2.RIGHT) + (launch_velocity.dot(Vector2.UP) * launch_strength_y * Vector2.UP)
  player.apply_launch(launch_velocity, 0.4, true)


func stack_garbo(other: Garbo):
  var how_many_garbos_to_add = 1 + other.stacked_objects.size()
  for _i in how_many_garbos_to_add:
    add_garbo_to_stack()

  update_collider()

  other.queue_free()


# YOU MUST CALL update_collider() AFTER CALLING THIS FUNCTION.
# also don't forget to queue_free() the garbo you stacked if applicable
func add_garbo_to_stack():
  var stack_target = stacked_objects[-1] if stacked_objects.size() > 0 else self
  var stacked_garbo_scene = stacked_garbo_a_scene if randi() % 2 == 0 else stacked_garbo_b_scene
  var new_stacked_garbo: StackedGarbo = stacked_garbo_scene.instantiate()
  stacked_objects.push_back(new_stacked_garbo)
  stack_target.set_stacked_object(new_stacked_garbo)


func set_stacked_object(object: StackedGarbo):
  if stacked_objects.size() > 0:
    push_warning('you called set_stacked_object on me (a root garbo), but i already had a stacked object')
  stack_point.add_child(object)


func get_stack_check_point():
  if stacked_objects.size() == 0:
    return position
  return stacked_objects[-1].global_position


func get_true_center():
  if stacked_objects.size() == 0:
    return global_position
  var top_stacked_object: StackedGarbo = stacked_objects[-1]
  var top_y = top_stacked_object.stack_point.global_position.y
  var bottom_y = global_position.y + sprite_height / 2.0
  var true_height = bottom_y - top_y
  var center_y = true_height / 2.0 + top_y
  return Vector2(global_position.x, center_y)


func get_true_height():
  if stacked_objects.size() == 0:
    return sprite_height
  var top_stacked_object: StackedGarbo = stacked_objects[-1]
  var top_y = top_stacked_object.stack_point.global_position.y
  var bottom_y = global_position.y + sprite_height / 2.0
  return bottom_y - top_y


func update_collider():
  collider.global_position = get_true_center()
  collider.shape.height = get_true_height()
