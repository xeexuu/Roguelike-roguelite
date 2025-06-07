extends Node
class_name ShootingComponent

@export var bullet_speed: float = 500.0
@export var fire_rate: float = 0.2
@export var bullet_scene: PackedScene

var can_shoot: bool = true
var shoot_timer: Timer

signal bullet_fired(bullet: Bullet, direction: Vector2)

func _ready():
	shoot_timer = Timer.new()
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	if not bullet_scene:
		bullet_scene = load("res://scenes/projectiles/Bullet.tscn")

func _on_shoot_timer_timeout():
	can_shoot = true

func try_shoot(direction: Vector2, start_position: Vector2) -> bool:
	if not can_shoot or direction == Vector2.ZERO:
		return false
	
	shoot(direction.normalized(), start_position)
	return true

func shoot(direction: Vector2, start_position: Vector2):
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate() as Bullet
	if not bullet:
		return
	
	bullet.setup(direction, bullet_speed)
	bullet.global_position = start_position
	
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(bullet)
		bullet_fired.emit(bullet, direction)
		can_shoot = false
		shoot_timer.start()
