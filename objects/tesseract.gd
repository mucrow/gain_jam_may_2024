extends Area2D


@onready var sprite_anchor = $SpriteAnchor

var duration = 2.0
var range = 12.0

var period = 0.0


func _physics_process(dt):
  period = fmod(period + dt, duration)
  sprite_anchor.position.y = sin((period / duration) * 2.0 * PI) * (range / 2.0)
