extends Area2D


@onready var sound_effect: AudioStreamPlayer2D = $SoundEffect
@onready var sprite_anchor = $SpriteAnchor

var duration = 2.0
var y_range = 12.0

var period = 0.0

var collected = false


func _physics_process(dt):
  period = fmod(period + dt, duration)
  sprite_anchor.position.y = sin((period / duration) * 2.0 * PI) * (y_range / 2.0)


func on_body_entered(body: Node2D):
  if collected:
    return
  if body.is_in_group('player'):
    collected = true
    sound_effect.play()
    var sprite = $SpriteAnchor/Sprite
    sprite.visible = false
    var emitter: GPUParticles2D = $SpriteAnchor/Emitter
    var tween = get_tree().create_tween()
    tween.tween_property(emitter, 'modulate', Color.TRANSPARENT, 1)
    # this feels mildly hacky. if the tween lasted longer, we'd need to connect
    # to the end of that instead. but whatever lol.
    sound_effect.finished.connect(self.queue_free)
