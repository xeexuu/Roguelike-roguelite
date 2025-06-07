extends Area2D
class_name Bullet

@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2
var speed: float
var lifetime_timer: Timer

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	
	setup_sprite()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	lifetime_timer.start()

func setup_sprite():
	if not sprite.texture:
		var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		
		for x in range(8):
			for y in range(8):
				var dist = Vector2(x - 4, y - 4).length()
				if dist <= 3:
					image.set_pixel(x, y, Color.YELLOW)
				elif dist <= 4:
					image.set_pixel(x, y, Color.ORANGE)
		
		sprite.texture = ImageTexture.create_from_image(image)

func setup(new_direction: Vector2, new_speed: float):
	direction = new_direction.normalized()
	speed = new_speed
	rotation = direction.angle()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_lifetime_timeout():
	queue_free()

func _on_area_entered(area: Area2D):
	if area != self:
		hit_something()

func _on_body_entered(body: Node2D):
	if body is Player:
		return
	hit_something()

func hit_something():
	create_hit_effect()
	queue_free()

func create_hit_effect():
	var effect = Node2D.new()
	effect.position = global_position
	
	for i in range(3):
		var particle = Sprite2D.new()
		var particle_image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		particle_image.fill(Color.WHITE)
		particle.texture = ImageTexture.create_from_image(particle_image)
		
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		particle.position = offset
		effect.add_child(particle)
	
	get_tree().current_scene.add_child(effect)
	
	var effect_timer = Timer.new()
	effect_timer.wait_time = 0.2
	effect_timer.one_shot = true
	effect_timer.timeout.connect(func(): effect.queue_free())
	effect.add_child(effect_timer)
	effect_timer.start()
