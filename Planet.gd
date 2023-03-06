extends Area2D

signal ship_landed_on_me
signal provide_fuel

onready var fuel_reserve_bar := $FuelReserveBar

var fuel_reserve := 1000


func _ready() -> void:
	var player_ship = get_tree().get_root().find_node("PlayerShip", true, false)
	player_ship.connect("fuel_drain", self, "drain_fuel")


func _on_Planet_body_entered(body: Node) -> void:
	fuel_reserve_bar.visible = true
	emit_signal("ship_landed_on_me")
	print("Ship landed on me")


func drain_fuel(drain: float) -> void:
	if fuel_reserve > 0:
		fuel_reserve -= drain
		fuel_reserve_bar.value = fuel_reserve
		emit_signal("provide_fuel", drain)
		print("planet has this much left: ", fuel_reserve)
	else:
		print("planet is out of fuel")


func _on_Planet_body_exited(body: Node) -> void:
	fuel_reserve_bar.visible = false
