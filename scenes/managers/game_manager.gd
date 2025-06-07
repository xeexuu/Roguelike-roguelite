extends Node
class_name GameManager

@onready var level_manager = $LevelManager
@onready var player_manager = $PlayerManager
@onready var ui_manager = $UIManager

var current_level: int = 1
var game_state: String = "playing"
var player: Player
var mobile_controls: Control
var background_node: Node2D

func _ready():
	setup_window()
	create_jungle_background()
	await get_tree().process_frame
	setup_player()
	setup_mobile_controls()

func setup_window():
	var is_mobile = OS.has_feature("mobile")
	
	if is_mobile:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized():
	await get_tree().process_frame
	update_camera_limits()
	update_mobile_controls_position()

func update_camera_limits():
	if player and player.camera:
		pass

func update_mobile_controls_position():
	if mobile_controls and OS.has_feature("mobile"):
		var viewport_size = get_viewport().get_visible_rect().size
		mobile_controls.size = viewport_size
		mobile_controls.position = Vector2.ZERO

# NUEVO: Fondo de jungla en pixel art simple
func create_jungle_background():
	background_node = Node2D.new()
	background_node.name = "JungleBackground"
	background_node.z_index = -100
	add_child(background_node)
	
	# Crear sprite de fondo base
	var bg_sprite = Sprite2D.new()
	bg_sprite.name = "JungleBase"
	
	# Crear imagen pixel art de jungla (64x64 píxeles, repetible)
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Colores de la jungla
	var grass_color = Color(0.2, 0.4, 0.1)  # Verde oscuro base
	var light_grass = Color(0.3, 0.5, 0.2)  # Verde claro
	var tree_color = Color(0.1, 0.2, 0.05)  # Verde muy oscuro
	var dirt_color = Color(0.3, 0.2, 0.1)   # Marrón tierra
	
	# Llenar con color base de hierba
	image.fill(grass_color)
	
	# Añadir manchas de hierba más clara
	for i in range(20):
		var x = randi() % size
		var y = randi() % size
		var patch_size = randi_range(3, 8)
		
		for px in range(patch_size):
			for py in range(patch_size):
				var nx = (x + px) % size
				var ny = (y + py) % size
				if randf() > 0.3:  # Probabilidad de píxel
					image.set_pixel(nx, ny, light_grass)
	
	# Añadir algunos troncos/árboles
	for i in range(8):
		var x = randi() % (size - 4)
		var y = randi() % (size - 8)
		
		# Tronco vertical
		for ty in range(6):
			for tx in range(2):
				image.set_pixel(x + tx, y + ty, tree_color)
		
		# Hojas alrededor del tronco
		for lx in range(-2, 3):
			for ly in range(-2, 2):
				var leaf_x = (x + 1 + lx) % size
				var leaf_y = (y + ly) % size
				if randf() > 0.4:
					image.set_pixel(leaf_x, leaf_y, Color(0.15, 0.3, 0.1))
	
	# Añadir caminos de tierra
	for i in range(3):
		var start_x = randi() % size
		var start_y = randi() % size
		var length = randi_range(10, 20)
		
		for step in range(length):
			var path_x = (start_x + step + randi_range(-1, 2)) % size
			var path_y = (start_y + randi_range(-1, 2)) % size
			image.set_pixel(path_x, path_y, dirt_color)
	
	var texture = ImageTexture.create_from_image(image)
	bg_sprite.texture = texture
	
	# Hacer el sprite muy grande para cubrir toda el área de juego
	bg_sprite.scale = Vector2(80, 80)  # 64 * 80 = 5120 píxeles de cobertura
	bg_sprite.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
	bg_sprite.position = Vector2.ZERO
	
	background_node.add_child(bg_sprite)

func setup_player():
	if player_manager.get_child_count() > 0:
		player = player_manager.get_child(0) as Player
		if player:
			player.global_position = Vector2(0, 0)
			player.z_index = 10
			print("Player setup - Position: ", player.global_position, " Z-index: ", player.z_index)

func setup_mobile_controls():
	if not OS.has_feature("mobile"):
		return
	
	mobile_controls = Control.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile_controls.z_index = 100
	ui_manager.add_child(mobile_controls)
	
	await get_tree().process_frame
	create_movement_joystick()
	create_shooting_buttons()

func create_movement_joystick():
	var viewport_size = get_viewport().get_visible_rect().size
	
	var movement_container = Control.new()
	movement_container.name = "MovementContainer"
	movement_container.size = Vector2(180, 180)
	movement_container.position = Vector2(40, viewport_size.y - 220)
	mobile_controls.add_child(movement_container)
	
	# Fondo del joystick
	var joystick_bg = ColorRect.new()
	joystick_bg.color = Color(0.2, 0.2, 0.2, 0.6)
	joystick_bg.size = Vector2(140, 140)
	joystick_bg.position = Vector2(20, 20)
	movement_container.add_child(joystick_bg)
	
	# Hacer el fondo circular
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	style_box.corner_radius_top_left = 70
	style_box.corner_radius_top_right = 70
	style_box.corner_radius_bottom_left = 70
	style_box.corner_radius_bottom_right = 70
	
	# CORREGIDO: Usar TouchScreenButton en lugar de Button para mejor respuesta táctil
	var joystick_button = TouchScreenButton.new()
	joystick_button.texture_normal = create_circle_texture(140, Color(0.2, 0.2, 0.2, 0.6))
	joystick_button.size = Vector2(140, 140)
	joystick_button.position = Vector2(20, 20)
	movement_container.add_child(joystick_button)
	
	# Centro del joystick
	var joystick_center = ColorRect.new()
	joystick_center.color = Color(0.0, 0.8, 1.0, 0.9)
	joystick_center.size = Vector2(50, 50)
	joystick_center.position = Vector2(65, 65)
	movement_container.add_child(joystick_center)
	
	# CORREGIDO: Conectar señales del TouchScreenButton
	joystick_button.pressed.connect(_on_joystick_pressed.bind(movement_container, joystick_center))
	joystick_button.released.connect(_on_joystick_released.bind(movement_container, joystick_center))

# NUEVO: Función para crear texturas circulares
func create_circle_texture(size: int, color: Color) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = size / 2
	var radius = size / 2 - 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - center, y - center).length()
			if dist <= radius:
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

func create_shooting_buttons():
	var viewport_size = get_viewport().get_visible_rect().size
	var shoot_size = Vector2(70, 70)
	var button_spacing = 15
	
	var base_x = viewport_size.x - shoot_size.x - 30
	var base_y = viewport_size.y - shoot_size.y - 30
	var center_x = base_x - shoot_size.x - button_spacing
	var center_y = base_y - shoot_size.y - button_spacing
	
	# CORREGIDO: Usar TouchScreenButton para mejor respuesta
	var shoot_up = create_shoot_touch_button("↑", Color.CYAN, 0.7)
	shoot_up.size = shoot_size
	shoot_up.position = Vector2(center_x, center_y - shoot_size.y)
	shoot_up.pressed.connect(_on_shoot_button_pressed.bind(Vector2.UP))
	shoot_up.released.connect(_on_shoot_button_released.bind(Vector2.UP))
	mobile_controls.add_child(shoot_up)
	
	var shoot_left = create_shoot_touch_button("←", Color.YELLOW, 0.7)
	shoot_left.size = shoot_size
	shoot_left.position = Vector2(center_x - shoot_size.x, center_y)
	shoot_left.pressed.connect(_on_shoot_button_pressed.bind(Vector2.LEFT))
	shoot_left.released.connect(_on_shoot_button_released.bind(Vector2.LEFT))
	mobile_controls.add_child(shoot_left)
	
	var shoot_right = create_shoot_touch_button("→", Color.YELLOW, 0.7)
	shoot_right.size = shoot_size
	shoot_right.position = Vector2(center_x + shoot_size.x, center_y)
	shoot_right.pressed.connect(_on_shoot_button_pressed.bind(Vector2.RIGHT))
	shoot_right.released.connect(_on_shoot_button_released.bind(Vector2.RIGHT))
	mobile_controls.add_child(shoot_right)
	
	var shoot_down = create_shoot_touch_button("↓", Color.CYAN, 0.7)
	shoot_down.size = shoot_size
	shoot_down.position = Vector2(center_x, center_y + shoot_size.y)
	shoot_down.pressed.connect(_on_shoot_button_pressed.bind(Vector2.DOWN))
	shoot_down.released.connect(_on_shoot_button_released.bind(Vector2.DOWN))
	mobile_controls.add_child(shoot_down)

# NUEVO: Crear botones táctiles mejorados
func create_shoot_touch_button(text: String, color: Color, alpha: float = 0.6) -> TouchScreenButton:
	var button = TouchScreenButton.new()
	
	# Crear textura para el botón
	var normal_texture = create_button_texture(70, color, alpha)
	var pressed_texture = create_button_texture(70, color, alpha + 0.3)
	
	button.texture_normal = normal_texture
	button.texture_pressed = pressed_texture
	
	# Añadir label encima para el texto
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.size = Vector2(70, 70)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	
	return button

func create_button_texture(size: int, color: Color, alpha: float) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Crear rectángulo redondeado
	for x in range(size):
		for y in range(size):
			var corner_radius = 10
			var in_corner = false
			
			# Verificar esquinas
			if (x < corner_radius and y < corner_radius):
				in_corner = Vector2(x - corner_radius, y - corner_radius).length() > corner_radius
			elif (x >= size - corner_radius and y < corner_radius):
				in_corner = Vector2(x - (size - corner_radius), y - corner_radius).length() > corner_radius
			elif (x < corner_radius and y >= size - corner_radius):
				in_corner = Vector2(x - corner_radius, y - (size - corner_radius)).length() > corner_radius
			elif (x >= size - corner_radius and y >= size - corner_radius):
				in_corner = Vector2(x - (size - corner_radius), y - (size - corner_radius)).length() > corner_radius
			
			if not in_corner:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

# VARIABLES MEJORADAS PARA EL JOYSTICK
var joystick_pressed = false
var joystick_center_pos = Vector2.ZERO
var current_movement_direction = Vector2.ZERO
var joystick_container: Control
var joystick_knob: ColorRect

# CORREGIDAS: Funciones del joystick
func _on_joystick_pressed(container: Control, center: ColorRect):
	joystick_pressed = true
	joystick_container = container
	joystick_knob = center
	joystick_center_pos = container.global_position + Vector2(90, 90)

func _on_joystick_released(container: Control, center: ColorRect):
	joystick_pressed = false
	current_movement_direction = Vector2.ZERO
	center.position = Vector2(65, 65)

# NUEVO: Detectar input táctil para el joystick
func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	
	# CORREGIDO: Manejo mejorado del joystick táctil
	if OS.has_feature("mobile") and joystick_pressed and joystick_container and joystick_knob:
		if event is InputEventScreenDrag:
			var drag_event = event as InputEventScreenDrag
			var local_pos = drag_event.position - joystick_center_pos
			var distance = local_pos.length()
			var max_distance = 45.0  # Reducido para mejor control
			
			if distance > max_distance:
				local_pos = local_pos.normalized() * max_distance
			
			joystick_knob.position = Vector2(65, 65) + local_pos
			current_movement_direction = local_pos.normalized() if distance > 5 else Vector2.ZERO

var active_shoot_directions = {}

func _on_shoot_button_pressed(direction: Vector2):
	active_shoot_directions[direction] = true

func _on_shoot_button_released(direction: Vector2):
	active_shoot_directions.erase(direction)

# OPTIMIZADO: Procesar input móvil de forma más eficiente
func _process(_delta):
	if OS.has_feature("mobile"):
		simulate_mobile_input()

func simulate_mobile_input():
	if not player:
		return
	
	# CORREGIDO: Aplicar movimiento de móvil sin lag
	player.mobile_movement_direction = current_movement_direction
	
	# CORREGIDO: Manejar disparos de móvil independientemente del movimiento
	for direction in active_shoot_directions:
		if player.shooting_component:
			player.shooting_component.try_shoot(direction, player.global_position)

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
