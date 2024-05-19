extends StaticBody2D

@export var spawn_garbo_interval: float = 5

var garbo_scene = preload("res://mobs/garbo.tscn")

func _ready():
  $GarboSpawnTimer.timeout.connect(spawn_garbo)
  $GarboSpawnTimer.start()

func _process(_dt):
  if $GarboSpawnTimer.is_stopped():
    $GarboSpawnTimer.start()


func spawn_garbo():
  var new_garbo: Garbo = garbo_scene.instantiate()
  new_garbo.position = position
  get_parent().add_child(new_garbo)
