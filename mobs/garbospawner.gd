extends StaticBody2D

@export var spawn_garbo_interval: float = 5

var garbo_scene = preload("res://mobs/garbo.tscn")

func _ready():
  $GarboSpawnTimer.timeout.connect(spawnGarbo)
  $GarboSpawnTimer.start()

func _process(_dt):
  if $GarboSpawnTimer.is_stopped():
    $GarboSpawnTimer.start()
    
    
func spawnGarbo():
  var newGarbo: Garbo = garbo_scene.instantiate()
  newGarbo.position = position
  get_parent().add_child(newGarbo)
  pass
