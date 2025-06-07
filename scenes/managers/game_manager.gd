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
	create_optimized_background()
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

func create_optimized_background():
	# Crear el fondo como Node2D en lugar de CanvasLayer
	background_node = Node2D.new()
	background_node.name = "OptimizedBackground"
	background_node.z_index = -100  # Muy por detrás del jugador
	
	# Añadir al nodo principal, NO al UIManager
	add_child(background_node)
	
	# Crear el fondo de color
	var background_sprite = Sprite2D.new()
	background_sprite.name = "BackgroundSprite"
	
	# Crear una textura de fondo grande
	var image = Image.create(4000, 4000, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.05, 0.05, 0.15, 1.0))
	var texture = ImageTexture.create_from_image(image)
	
	background_sprite.texture = texture
	background_sprite.position = Vector2.ZERO  # Centrado en el origen
	background_sprite.z_index = -100
	
	background_node.add_child(background_sprite)
	
	create_simple_pattern_overlay(background_node)

func create_simple_pattern_overlay(parent: Node2D):
	var pattern = Node2D.new()
	pattern.name = "Pattern"
	pattern.z_index = -90  # Por encima del fondo pero detrás del jugador
	parent.add_child(pattern)
	
	# Crear algunos puntos de referencia más visibles
	for i in range(50):
		var dot = Sprite2D.new()
		
		# Crear textura para el punto
		var dot_image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
		dot_image.fill(Color(0.0, 0.8, 1.0, 0.5))
		var dot_texture = ImageTexture.create_from_image(dot_image)
		
		dot.texture = dot_texture
		dot.position = Vector2(
			randf_range(-2000, 2000),
			randf_range(-2000, 2000)
		)
		pattern.add_child(dot)
		
		if i % 3 == 0:
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(dot, "modulate:a", 0.2, 2.0)
			tween.tween_property(dot, "modulate:a", 0.8, 2.0)

func setup_player():
	if player_manager.get_child_count() > 0:
		player = player_manager.get_child(0) as Player
		if player:
			# Posición inicial centrada en el origen del mundo
			player.global_position = Vector2(0, 0)
			player.z_index = 10  # Por encima del fondo
			
			print("Player setup - Position: ", player.global_position, " Z-index: ", player.z_index)

func setup_mobile_controls():
	if not OS.has_feature("mobile"):
		return
	
	mobile_controls = Control.new()
	mobile_controls.name = "MobileControls"
	mobile_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mobile_controls.z_index = 100  # Por encima de todo
	ui_manager.add_child(mobile_controls)
	
	create_movement_joystick()
	create_shooting_buttons()

func create_movement_joystick():
	var movement_container = Control.new()
	movement_container.name = "MovementContainer"
	movement_container.size = Vector2(200, 200)
	movement_container.position = Vector2(50, get_viewport().get_visible_rect().size.y - 250)
	mobile_controls.add_child(movement_container)
	
	var joystick_bg = ColorRect.new()
	joystick_bg.color = Color(0.2, 0.2, 0.2, 0.5)
	joystick_bg.size = Vector2(150, 150)
	joystick_bg.position = Vector2(25, 25)
	joystick_bg.pivot_offset = joystick_bg.size / 2
	movement_container.add_child(joystick_bg)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	style_box.corner_radius_top_left = 75
	style_box.corner_radius_top_right = 75
	style_box.corner_radius_bottom_left = 75
	style_box.corner_radius_bottom_right = 75
	
	var joystick_button = Button.new()
	joystick_button.flat = true
	joystick_button.add_theme_stylebox_override("normal", style_box)
	joystick_button.size = Vector2(150, 150)
	joystick_button.position = Vector2(25, 25)
	movement_container.add_child(joystick_button)
	
	var joystick_center = ColorRect.new()
	joystick_center.color = Color(0.0, 0.8, 1.0, 0.8)
	joystick_center.size = Vector2(60, 60)
	joystick_center.position = Vector2(70, 70)
	movement_container.add_child(joystick_center)
	
	joystick_button.gui_input.connect(_on_joystick_input.bind(movement_container, joystick_center))

func create_shooting_buttons():
	var viewport_size = get_viewport().get_visible_rect().size
	
	var shoot_size = Vector2(80, 80)
	
	var shoot_up = create_shoot_button("↑", Color.CYAN)
	shoot_up.size = shoot_size
	shoot_up.position = Vector2(viewport_size.x - 150, viewport_size.y - 300)
	shoot_up.pressed.connect(_on_shoot_button_pressed.bind(Vector2.UP))
	shoot_up.button_up.connect(_on_shoot_button_released.bind(Vector2.UP))
	mobile_controls.add_child(shoot_up)
	
	var shoot_left = create_shoot_button("←", Color.YELLOW)
	shoot_left.size = shoot_size
	shoot_left.position = Vector2(viewport_size.x - 230, viewport_size.y - 220)
	shoot_left.pressed.connect(_on_shoot_button_pressed.bind(Vector2.LEFT))
	shoot_left.button_up.connect(_on_shoot_button_released.bind(Vector2.LEFT))
	mobile_controls.add_child(shoot_left)
	
	var shoot_right = create_shoot_button("→", Color.YELLOW)
	shoot_right.size = shoot_size
	shoot_right.position = Vector2(viewport_size.x - 70, viewport_size.y - 220)
	shoot_right.pressed.connect(_on_shoot_button_pressed.bind(Vector2.RIGHT))
	shoot_right.button_up.connect(_on_shoot_button_released.bind(Vector2.RIGHT))
	mobile_controls.add_child(shoot_right)
	
	var shoot_down = create_shoot_button("↓", Color.CYAN)
	shoot_down.size = shoot_size
	shoot_down.position = Vector2(viewport_size.x - 150, viewport_size.y - 140)
	shoot_down.pressed.connect(_on_shoot_button_pressed.bind(Vector2.DOWN))
	shoot_down.button_up.connect(_on_shoot_button_released.bind(Vector2.DOWN))
	mobile_controls.add_child(shoot_down)

func create_shoot_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.flat = false
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(color.r, color.g, color.b, 0.6)
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(color.r, color.g, color.b, 0.9)
	style_pressed.corner_radius_top_left = 10
	style_pressed.corner_radius_top_right = 10
	style_pressed.corner_radius_bottom_left = 10
	style_pressed.corner_radius_bottom_right = 10
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	return button

var joystick_pressed = false
var joystick_center_pos = Vector2.ZERO
var current_movement_direction = Vector2.ZERO

func _on_joystick_input(event: InputEvent, container: Control, center: ColorRect):
	if event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		if touch_event.pressed:
			joystick_pressed = true
			joystick_center_pos = container.global_position + Vector2(100, 100)
		else:
			joystick_pressed = false
			current_movement_direction = Vector2.ZERO
			center.position = Vector2(70, 70)
	
	elif event is InputEventScreenDrag and joystick_pressed:
		var drag_event = event as InputEventScreenDrag
		var local_pos = drag_event.position - joystick_center_pos
		var distance = local_pos.length()
		var max_distance = 45.0
		
		if distance > max_distance:
			local_pos = local_pos.normalized() * max_distance
		
		center.position = Vector2(70, 70) + local_pos
		current_movement_direction = local_pos.normalized() if distance > 10 else Vector2.ZERO

var active_shoot_directions = {}

func _on_shoot_button_pressed(direction: Vector2):
	active_shoot_directions[direction] = true

func _on_shoot_button_released(direction: Vector2):
	active_shoot_directions.erase(direction)

func _process(_delta):
	if OS.has_feature("mobile"):
		simulate_mobile_input()

func simulate_mobile_input():
	if not player:
		return
	
	if current_movement_direction != Vector2.ZERO:
		player.velocity = current_movement_direction * player.speed
	else:
		player.velocity = Vector2.ZERO
	
	for direction in active_shoot_directions:
		if player.shooting_component:
			player.shooting_component.try_shoot(direction, player.global_position)

func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		toggle_fullscreen()

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
