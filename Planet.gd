extends Area2D

signal ship_landed_on_me
signal apply_gravity_pull
signal remove_gravity_pull

onready var fuel_reserve_bar := $FuelReserveBar
onready var planet_position := self.position
onready var fuel_resource = preload("res://FuelReserve.tscn").instance()
onready var planet_name := get_name()


func _ready() -> void:
	randomize()
	print("Planet ", planet_name," is at position: ", planet_position)
	add_to_group("planets")
	
	# creates a child of fuel resource for this planet (its own fuel reserve)
	add_child(fuel_resource)
	fuel_resource.fuel_reserve = rand_range(100.0, 1000.0)
	fuel_reserve_bar.value = fuel_resource.fuel_reserve
	
	var player_ship = get_tree().get_root().find_node("PlayerShip", true, false)
	player_ship.connect("mine_fuel", self, "drain_fuel")

# drains fuel from the planet where the ship is currently landed
func drain_fuel(drain: float, current_planet_name) -> void:
	if planet_name == current_planet_name:
		var planet = get_node("/root/TestGalaxy/" + current_planet_name)
#		print("planet path: ", planet)
		var current_fuel_reserve = planet.get_node("FuelReserve")
#		print("fuel node: ", current_fuel_reserve)
		# we check if the planet has any fuel to give
		if current_fuel_reserve.fuel_reserve > 0:
			# if YES, we check if we can do give the requested amount or there is less than that
			var check_positive_reserve = current_fuel_reserve.fuel_reserve - drain
			if check_positive_reserve < 0:
				# if there is less, the planet gives only what remains above zero fuel
				var lower_drain = current_fuel_reserve.fuel_reserve
				current_fuel_reserve.fuel_reserve -= lower_drain
				fuel_reserve_bar.value = current_fuel_reserve.fuel_reserve
				print("fuel of planet - ", current_planet_name, " - DROPS to: ", current_fuel_reserve.fuel_reserve)
			else:
				# otherwise the planet loses a full amount of fuel based on the drain value
				current_fuel_reserve.fuel_reserve -= drain
				fuel_reserve_bar.value = current_fuel_reserve.fuel_reserve
#				emit_signal("provide_fuel", drain)
				print("fuel of planet - ", current_planet_name, " - is now: ", current_fuel_reserve.fuel_reserve)
		else:
			print(planet_name, " is out of fuel!")

# when ship lands on this planet, we display its fuel bar
func _on_Planet_body_entered(body: Node) -> void:
	if body.name == "PlayerShip":
		fuel_reserve_bar.visible = true
		emit_signal("ship_landed_on_me", planet_name)
		print("Ship landed on me: ", planet_name)

# once the ship leaves, we hide the fuel bar
func _on_Planet_body_exited(body: Node) -> void:
	if body.name == "PlayerShip":
		fuel_reserve_bar.visible = false

# when ship enters the gravty area of this planet, it sends it a signal to start pulling it in
func _on_Gravity_field_body_entered(body: Node) -> void:
	if body.name == "PlayerShip":
		emit_signal("apply_gravity_pull", planet_position)
		print("signal emitted: Gravity_field_body_ENTERED")

# once the ship leaves the gravity area, it sends it a signal to turn the gravity off
func _on_Gravity_field_body_exited(body: Node) -> void:
	if body.name == "PlayerShip":
		emit_signal("remove_gravity_pull")
		print("signal emitted: Gravity_field_body_EXITED")
