extends KinematicBody2D

signal fuel_drain

onready var ship := $Sprite
onready var particles := $Particles2D
onready var fuel_bar := $FuelBar
onready var end_phrase := $EndPhrase
onready var raycast := $RayCast2D
onready var look_direction := $LookDirection
onready var timer := $Timer

export var max_speed := 600.0
export var drag_factor := 0.01
export var deceleration := 200

var current_speed := 0
var velocity := Vector2.ZERO
var ship_fuel := 500
var fuel_mining_speed := 50
var can_move := true
var is_landed := false

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

# I borrowed (stole) some pieces of this code from GDQuest, so credit goes to them

func _ready() -> void:
	var planet = get_tree().get_root().find_node("Planet", true, false)
	planet.connect("ship_landed_on_me", self, "ship_landed")
	planet.connect("provide_fuel", self, "gain_fuel")
	
	randomize()
	cry()


func _physics_process(delta: float) -> void:
	move(delta)
	
	if is_equal_approx(ship_fuel, 0) and is_equal_approx(current_speed, 0):
		end_phrase.visible = true


func move(delta: float) -> void:
	var direction := Vector2.ZERO
	var relative_cursor_position := get_local_mouse_position()
	direction = relative_cursor_position.normalized()
	draw_line_to_cursor()

	if Input.is_action_pressed("move") and ship_fuel > 0 and can_move:
		set_speed(max_speed)
		spend_fuel(1)
		particles.emitting = true
	elif Input.is_action_pressed("move") and ship_fuel > 0 and can_move == false and raycast.get_collider() == null:
		can_move = true
		is_landed = false
		timer.stop()
	else:
		current_speed -= deceleration * delta
		if current_speed <= 0:
			current_speed = 0
		particles.emitting = false
	
	var desired_velocity := current_speed * direction
	var steering_vector := desired_velocity - velocity
	velocity += steering_vector * drag_factor
	
	velocity = move_and_slide(velocity)
	ship.rotation = velocity.angle()


func set_speed(speed: float) -> void:
	current_speed = speed


func spend_fuel(burn: float) -> void:
	ship_fuel -= burn
	fuel_bar.value = ship_fuel


func gain_fuel(gain: float) -> void:
	ship_fuel += gain
	fuel_bar.value = ship_fuel
	print("ship gained gained fuel, it's now: ", ship_fuel)


func cry() -> void:
	end_phrase.text = str(cries[randi() % cries.size()])


func draw_line_to_cursor() -> void:
	var cursor := Vector2.ZERO
	cursor = get_global_mouse_position()
	raycast.look_at(cursor)
	raycast.force_raycast_update()
	look_direction.vector = to_local(cursor)


func ship_landed() -> void:
	is_landed = true


func _on_Planet_body_entered(body: Node) -> void:
	can_move = false
	current_speed = 0
	velocity = Vector2.ZERO
	timer.start()


func _on_Timer_timeout() -> void:
	gain_fuel(fuel_mining_speed)
	emit_signal("fuel_drain", fuel_mining_speed)
