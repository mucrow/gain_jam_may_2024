extends Node2D
class_name StackedGarbo


@onready var sprite = $Sprite2D
@onready var stack_point = $Sprite2D/StackPoint

var stacked_object: Node2D = null


func toggle_sprite_flip_h():
  set_sprite_flip_h(!sprite.flip_h)


func set_sprite_flip_h(flipped):
  sprite.flip_h = flipped


func set_stacked_object(object: Node2D):
  if stacked_object != null:
    push_warning('you called set_stacked_object on me, but i already had a stacked object')
  stacked_object = object
  stack_point.add_child(object)


func remove_stacked_object():
  if stacked_object != null:
    stack_point.remove_child(stacked_object)
    var ret = stacked_object
    stacked_object = null
    return ret


func free_stacked_object():
  if stacked_object != null:
    stacked_object.queue_free()
    stacked_object = null
