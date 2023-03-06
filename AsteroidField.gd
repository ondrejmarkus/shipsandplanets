extends Node2D

var asteroid_scene := preload("res://Asteroid.tscn")

onready var asteroid_spawn_timer := $AsteroidSpawnTimer
onready var asteroid_spawn_path := $AsteroidPath/AsteroidSpawn


func _ready() -> void:
	randomize()

# every X seconds we generate a new asteroid on a Path2D drawn around the world
# it has randomized position, scale, direciton, and velocity
# (this code is pretty much taken from the example game in Godot's documentation: Dodge the Creeps)
func _on_AsteroidSpawnTimer_timeout() -> void:
	var asteroid := asteroid_scene.instance()
	var asteroid_spawn_location = asteroid_spawn_path
	asteroid_spawn_location.offset = randi()
	# set asteroid direction perpendicular to the path direction
	var asteroid_direction = asteroid_spawn_location.rotation + PI / 2
	# set the asteroid's position to a random location
	asteroid.position = asteroid_spawn_location.position
	# add some randomness to the direction
	asteroid_direction += rand_range(-PI / 4, PI / 4)
	asteroid.rotation = asteroid_direction
	# choose a randomize velocity for the asteroid
	var asteroid_velocity = Vector2(rand_range(200.0, 400.0), 0.0)
	asteroid.linear_velocity = asteroid_velocity.rotated(asteroid_direction)
	add_child(asteroid)
