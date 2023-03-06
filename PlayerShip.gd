extends KinematicBody2D

signal mine_fuel

onready var ship := $Sprite
onready var particles := $Particles2D
onready var fuel_bar := $FuelBar
onready var end_phrase := $EndPhrase
onready var raycast := $RayCast2D
onready var look_direction := $LookDirection
onready var refuel_timer := $RefuelTimer
onready var ship_explosion_animation := $ShipExplosionAnimation
onready var ship_explosion := $ShipExplosion
onready var reset_button := $ResetButton

# max_speed is the speed the ship gets whenever spacebar is pressed
export var max_speed := 600.0
# drag_factor defines the agility of the ship's reactions: lower number = slower steering
export var drag_factor := 0.3
# decelaration defines how quickly the ship loses speed when the engines are off
export var deceleration := 200.0

var velocity := Vector2.ZERO
var gravity_source := Vector2.ZERO
var gravity_vector := Vector2.ZERO

var current_speed := 0.0
var max_ship_fuel := 500.0
var ship_fuel := 400.0
var fuel_mining_speed := 50.0
var gravity_power := 50.0

var game_on := true
var can_move := true
var is_landed := false

var current_planet
var current_planet_name

var cries := [
	"oh no",
	"yayx",
	"we're out",
	"mayday mayday",
	"Houstan?",
	"we're screwed",
	"not again...",
	"help!"
]


func _ready() -> void:
	fuel_bar.value = ship_fuel
	# communication with planets, loops through all planets and connects signals
	var planets := get_tree().get_nodes_in_group("planets")
	for planet in planets:
		planet.connect("ship_landed_on_me", self, "ship_landed")
#		planet.connect("provide_fuel", self, "gain_fuel")
		planet.connect("apply_gravity_pull", self, "apply_gravity_pull")
		planet.connect("remove_gravity_pull", self, "remove_gravity_pull")
	
	# cry function picks a random end game phrase to show
	randomize()
	cry()


func _physics_process(delta: float) -> void:
	if game_on:
		move(delta)
	# if ship fuel and speed are zero, we display one of the crying phrases next to the ship
	if is_equal_approx(ship_fuel, 0) and is_equal_approx(current_speed, 0) and can_move == true:
		end_phrase.visible = true


func new_game():
	print("NEW GAME STARTED")
	game_on = true
	can_move = true
	velocity = Vector2.ZERO
	current_speed = 0.0
	ship.visible = true
	fuel_bar.visible = true
#	raycast.visible = true
#	look_direction.visible = true
	position = Vector2(933, 519)
	reset_button.visible = false


func game_over():
	print("--- GAME OVER ---")
	game_on = false
	can_move = false
	reset_button.visible = true


func move(delta: float) -> void:
	# set direction to face cursor position and normalize it (shorten the vector to 1)
	var direction := Vector2.ZERO
	direction = get_cursor_position().normalized()
	
	# draw line to cursor that also includes Raycast2D checking for overlaps (separate later)
	draw_line_to_cursor()
	
	# main movement decision tree
	# if SPACEBAR is pressed and ship has fuel and it's not landed, the ship increases its speed
	if Input.is_action_pressed("move") and ship_fuel > 0 and can_move:
		increase_speed(20)
		spend_fuel(1)
		particles.emitting = true
	# if ship is landed and the cursor points away from the current planet, ship takes off
	elif Input.is_action_pressed("move") and ship_fuel > 0 and can_move == false and raycast.get_collider() == null:
		can_move = true
		is_landed = false
		refuel_timer.stop()
	# if neither is true, the ship slows down by some amount every second and particles are off
	else:
		current_speed -= deceleration * delta
		if current_speed <= 0:
			current_speed = 0
		particles.emitting = false
	
	# moves the ship alongside the difference between current velocity and desired velocity every frame
	# drag_factor influences how quickly the ship reacts to change of direction (lower = slower)
	var desired_velocity := current_speed * direction
	var steering_vector := desired_velocity - velocity 
	velocity += steering_vector * drag_factor * delta
	
	velocity = move_and_slide(velocity)
#	position += velocity * delta
	if can_move:
		ship.rotation = velocity.angle()
	
	# apply gravity pull if there is any gravity source nearby
	if gravity_source != Vector2.ZERO:
		gravity_pull(delta)

# pulls the ship towards the gravity source
func gravity_pull(delta) -> void:
	gravity_vector = to_local(gravity_source)
	var gravity_direction := gravity_vector.normalized()
	var gravity_velocity := gravity_direction * gravity_power
	if can_move:
		position += gravity_velocity * delta

# sets the nearby planet position as gravity source
func apply_gravity_pull(planet_position: Vector2) -> void:
	gravity_source = planet_position
	print("gravity pull directed to: ", gravity_source)

# removes current gravity source
func remove_gravity_pull() -> void:
	gravity_source = Vector2.ZERO
	print("gravity pull set to ZERO")


func get_cursor_position():
	var relative_cursor_position := get_local_mouse_position()
	return relative_cursor_position


func increase_speed(speed: float) -> void:
	if current_speed < max_speed:
		current_speed += speed


func spend_fuel(burn: float) -> void:
	ship_fuel -= burn
	fuel_bar.value = ship_fuel

# takes a random phrase from the cries array
func cry() -> void:
	end_phrase.text = str(cries[randi() % cries.size()])

# projects and draws a line from ship to cursor
func draw_line_to_cursor() -> void:
	var cursor := Vector2.ZERO
	cursor = get_global_mouse_position()
	raycast.look_at(cursor)
	raycast.force_raycast_update()
	look_direction.vector = to_local(cursor)

# when ship enters a planet, it stops moving and starts the refueling timer
func ship_landed(planet_name) -> void:
	print("Ship landed on: ", current_planet_name)
	current_planet_name = planet_name
	can_move = false
	is_landed = true
	current_speed = 0
	velocity = Vector2.ZERO
	refuel_timer.start()

# timer calls gain fuel function every second
func _on_RefuelTimer_timeout() -> void:
	gain_fuel(fuel_mining_speed)
	print("---TIMER TICK---")

# increases fuel of the ship every time it's called by the gain value
func gain_fuel(gain: float) -> void:
	# first we look on what planet is the ship getting its fuel
	current_planet = get_node("/root/TestGalaxy/" + current_planet_name)
	var current_fuel_reserve = current_planet.get_node("FuelReserve")
	# then we check if the planet has any fuel left in its reserves
	if current_fuel_reserve.fuel_reserve > 0:
		# if YES, we check if the ship has any empty space left for fuel
		if ship_fuel < max_ship_fuel:
			var check_max_fuel = ship_fuel + gain
			# if YES, we check if we can do a full increase this second, or a lower one because
			# we would go over the maximum fuel allowed
			if check_max_fuel > max_ship_fuel:
				# if that's the case, we increase the fuel only by what is missing to the maximum
				var lower_gain = max_ship_fuel - ship_fuel
				ship_fuel += lower_gain
				fuel_bar.value = ship_fuel
				emit_signal("mine_fuel", lower_gain, current_planet_name)
				print("ship gained LESS fuel, it's now: ", ship_fuel)
			else:
				# otherwise we just increase the fuel by the fuel_mining_speed every second
				ship_fuel += gain
				fuel_bar.value = ship_fuel
				emit_signal("mine_fuel", fuel_mining_speed, current_planet_name)
				print("ship gained gained fuel, it's now: ", ship_fuel)
	# lastly, if the cry was visible, we turn it off again (quick fix for premature crying)
	if end_phrase.visible:
		end_phrase.visible = false


# signal that registers collision with asteroids and makes the ship explode on contact
func _on_SafetyArea_body_entered(body: Node) -> void:
	if body.is_in_group("asteroids"):
		ship_explosion_animation.play("ship_explosion")


func _on_ResetButton_pressed() -> void:
	new_game()
