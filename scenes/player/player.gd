extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var shooting_sprite_duration: float = 0.15

@onready var sprite = $Sprite2D
@onready var camera = $Camera2D
@onready var shooting_component = $ShootingComponent

var debug_label: Label
var bullets_fired: int = 0

# Texturas del jugador
var normal_texture: Texture2D
var shooting_texture: Texture2D
var sprite_timer: Timer
var is_shooting_sprite_active: bool = false

# Variables para el efecto de glow (optimizado)
var glow_timer: Timer
var base_modulate: Color = Color.WHITE
var is_mobile: bool

func _ready():
	is_mobile = OS.has_feature("mobile")
	z_index = 50  # Asegurar que esté muy por encima del fondo
	
	setup_sprite_from_file()
	setup_camera()
	create_debug_ui()
	setup_shooting()
	setup_sprite_timer()
	
	if not is_mobile:
		setup_glow_effect()
	
	print("Player _ready - Position: ", global_position, " Z-index: ", z_index)

func setup_camera():
	if camera:
		camera.enabled = true
		camera.make_current()
		if is_mobile:
			camera.zoom = Vector2(1.5, 1.5)
		else:
			camera.zoom = Vector2(2.0, 2.0)

func setup_sprite_from_file():
	normal_texture = load("res://sprites/player/player.png")
	shooting_texture = load("res://sprites/player/player_shooting.png")
	
	if normal_texture:
		sprite.texture = normal_texture
		print("Loaded normal texture successfully")
	else:
		print("Normal texture not found, using debug sprite")
		setup_debug_sprite()
	
	if not shooting_texture:
		print("Shooting texture not found, creating debug shooting sprite")
		create_shooting_sprite()

func setup_debug_sprite():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Crear un sprite más visible para debug
	for x in range(64):
		for y in range(64):
			# Cuerpo principal más grande
			if x >= 8 and x < 56 and y >= 8 and y < 56:
				var center_dist = Vector2(x - 32, y - 32).length()
				if center_dist < 20:
					image.set_pixel(x, y, Color.CYAN)
			
			# Ojos más grandes
			if (x >= 20 and x < 28 and y >= 20 and y < 28) or (x >= 36 and x < 44 and y >= 20 and y < 28):
				image.set_pixel(x, y, Color.WHITE)
			
			# Línea central más visible
			if x >= 24 and x < 40 and y >= 30 and y < 38:
				image.set_pixel(x, y, Color.YELLOW)
	
	normal_texture = ImageTexture.create_from_image(image)
	sprite.texture = normal_texture
	print("Debug sprite created and assigned")

func create_shooting_sprite():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Sprite de disparo más visible
	for x in range(64):
		for y in range(64):
			# Cuerpo principal
			if x >= 8 and x < 56 and y >= 8 and y < 56:
				var center_dist = Vector2(x - 32, y - 32).length()
				if center_dist < 20:
					image.set_pixel(x, y, Color.ORANGE)
			
			# Ojos
			if (x >= 20 and x < 28 and y >= 20 and y < 28) or (x >= 36 and x < 44 and y >= 20 and y < 28):
				image.set_pixel(x, y, Color.WHITE)
			
			# Efectos de disparo laterales más visibles
			if (x >= 0 and x < 16 and y >= 24 and y < 40) or (x >= 48 and x < 64 and y >= 24 and y < 40):
				image.set_pixel(x, y, Color.YELLOW)
	
	shooting_texture = ImageTexture.create_from_image(image)

func create_debug_ui():
	debug_label = Label.new()
	debug_label.text = "Pos: (0, 0)"
	debug_label.add_theme_font_size_override("font_size", 20)  # Reducido para móvil
	debug_label.modulate = Color.YELLOW
	debug_label.z_index = 100
	
	# Configurar anclaje para que se mantenga en una posición fija relativa a la cámara
	debug_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	
	# Añadir al nodo de la cámara para que se mueva con ella
	camera.add_child(debug_label)
	
	# Configurar posición inicial
	update_debug_label_position()

func update_debug_label_position():
	if not debug_label or not camera:
		return
	
	# Obtener el tamaño del viewport actual
	var viewport = get_viewport()
	if not viewport:
		return
	
	var viewport_size = viewport.get_visible_rect().size
	var zoom = camera.zoom
	
	# Calcular el tamaño visible del mundo en coordenadas de cámara
	var visible_size = viewport_size / zoom
	
	# Posicionar el label en la esquina superior izquierda, pero dentro del área visible
	var margin = Vector2(10, 10) # Margen desde el borde
	var label_pos = -visible_size * 0.5 + margin
	
	debug_label.position = label_pos
	
	# Asegurar que el texto no sea demasiado largo para la pantalla
	if is_mobile:
		debug_label.add_theme_font_size_override("font_size", 16)
	else:
		debug_label.add_theme_font_size_override("font_size", 20)

func setup_glow_effect():
	glow_timer = Timer.new()
	glow_timer.wait_time = 0.1
	glow_timer.timeout.connect(_on_glow_timer_timeout)
	add_child(glow_timer)
	glow_timer.start()

func _on_glow_timer_timeout():
	var current_time = Time.get_ticks_msec() / 1000.0
	var glow_intensity = (sin(current_time * 3) + 1) / 2
	var glow_color = Color(1.1 + glow_intensity * 0.2, 1.05 + glow_intensity * 0.1, 1.0 + glow_intensity * 0.3)
	sprite.modulate = glow_color

func setup_sprite_timer():
	sprite_timer = Timer.new()
	sprite_timer.wait_time = shooting_sprite_duration
	sprite_timer.one_shot = true
	sprite_timer.timeout.connect(_on_sprite_timer_timeout)
	add_child(sprite_timer)

func _on_sprite_timer_timeout():
	change_to_normal_sprite()

func setup_shooting():
	if shooting_component:
		shooting_component.bullet_fired.connect(_on_bullet_fired)

func _on_bullet_fired(bullet: Bullet, direction: Vector2):
	bullets_fired += 1
	change_to_shooting_sprite()
	
	if not is_mobile:
		create_shooting_flash()
	
	if bullet and bullet.sprite:
		match direction:
			Vector2.UP, Vector2.DOWN:
				bullet.sprite.modulate = Color.CYAN
			Vector2.LEFT, Vector2.RIGHT:
				bullet.sprite.modulate = Color.YELLOW
			_:
				bullet.sprite.modulate = Color.WHITE

func create_shooting_flash():
	sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func change_to_shooting_sprite():
	if shooting_texture:
		sprite.texture = shooting_texture
		is_shooting_sprite_active = true
		sprite_timer.start()

func change_to_normal_sprite():
	if normal_texture:
		sprite.texture = normal_texture
		is_shooting_sprite_active = false

func _physics_process(_delta):
	if not is_mobile:
		handle_movement()
		handle_shooting()
	
	move_and_slide()
	update_debug_ui()

func handle_shooting():
	if not shooting_component:
		return
	
	var shoot_direction = Vector2.ZERO
	
	if Input.is_action_pressed("shoot_left"):
		shoot_direction.x -= 1
	if Input.is_action_pressed("shoot_right"):
		shoot_direction.x += 1
	if Input.is_action_pressed("shoot_up"):
		shoot_direction.y -= 1
	if Input.is_action_pressed("shoot_down"):
		shoot_direction.y += 1
	
	if shoot_direction != Vector2.ZERO:
		shooting_component.try_shoot(shoot_direction, global_position)

func handle_movement():
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	velocity = input_vector.normalized() * speed

func update_debug_ui():
	if debug_label:
		var can_shoot_text = "🔫" if shooting_component and shooting_component.can_shoot else "⏳"
		var sprite_status = "🔥" if is_shooting_sprite_active else "🟦"
		var mobile_text = "📱" if is_mobile else "🖥️"
		
		# Texto más corto para móvil
		if is_mobile:
			debug_label.text = "(%d,%d) %s S:%d %s" % [
				int(global_position.x), 
				int(global_position.y),
				can_shoot_text,
				bullets_fired,
				sprite_status
			]
		else:
			debug_label.text = "Pos: (%d, %d) | %s | Shots: %d | %s %s | Z: %d" % [
				int(global_position.x), 
				int(global_position.y),
				can_shoot_text,
				bullets_fired,
				sprite_status,
				mobile_text,
				z_index
			]
		
		# Actualizar posición del label cada cierto tiempo para evitar que se salga
		update_debug_label_position()
