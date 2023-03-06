extends RigidBody2D

onready var asteroid_sprite := $Sprite
onready var explosion_animation := $ExplosionAnimation
onready var asteroid_collision_shape := $CollisionShape2D
onready var asteroid_area_shape := $AsteroidArea/CollisionShape2D

var planet := preload("res://Planet.tscn")


func _ready() -> void:
	add_to_group("asteroids")
	
	# sets a random scale for each asteroid (same for collision shapes and sprite)
	randomize()
	var asteroid_scale = rand_range(0.1, 0.6)
	asteroid_sprite.scale = Vector2(asteroid_scale, asteroid_scale)
	asteroid_collision_shape.scale = Vector2(asteroid_scale, asteroid_scale)
	asteroid_area_shape.scale = Vector2(asteroid_scale, asteroid_scale)

# destroys the asteroid by starting the explosion animation
func explode() -> void:
	explosion_animation.play("explosion")

# when this asteroid collides with a planet, the asteroid explodes
func _on_AsteroidArea_area_entered(area: Area2D) -> void:
	if area.is_in_group("planets"):
		explode()

# if two asteroids collide, both explode
func _on_Asteroid_body_entered(body: Node) -> void:
	if body.is_in_group("asteroids"):
		explode()
