extends CharacterBody2D
class_name Player

# --- EXPORTS (Configurables desde el Inspector) ---
@export var sprite: AnimatedSprite2D
@export var sonido_jump: AudioStreamPlayer2D
@export var counter_group_name: String = "COUNTER"

# Modos Especiales
@export var moon_gravity_enabled := false 
@export var ice_mode_enabled := false     

# Modos Especiales Adicionales
@export var modo_hormiga := false
@export var modo_gigante := false
@export var gravedad_invertida := false
@export var supersaltos := false
@export var modo_borracho := false
@export var rastro_arcoiris := false

# Movimiento base
@export var speed := 100.0
@export var gravity := 800.0
@export var min_jump_force := -300.0
@export var max_jump_force := -450.0

# Hielo
@export var ice_acceleration := 2.0  
@export var ice_friction := 1.5      

# Juice (Tiempos de Gracia)
@export var coyote_time_duration := 0.15
@export var jump_buffer_duration := 0.15

# Rotación y Física
@export var max_angular_velocity := 5.0
@export var rotation_friction := 0.1
@export var rotation_torque := 80.0

# Visuales (Squash & Stretch)
@export var charge_color := Color(1, 0, 0)
@export var stretch_factor := 0.3
@export var squash_factor := 0.2
@export var scale_speed := 10.0

# Ghost Trail Config
@export var ghost_enabled := true
@export var ghost_spawn_interval := 0.05
@export var ghost_lifetime := 0.3

# --- VARIABLES INTERNAS ---
var original_rotation := 0.0
var original_color := Color(1, 1, 1)
var original_scale := Vector2.ONE
var angular_velocity := 0.0
var angular_acceleration := 0.0

var is_charging_jump := false
var jump_charge := 0.0
var max_charge_time := 1.0
var is_jumping := false
var landed := false

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var ghost_timer := 0.0

var last_jump_was_charged := false

var initial_y := 0.0
var height_climbed := 0.0
var displayed_value := 0
var counter_label: Label

func _ready() -> void:
	initial_y = position.y
	original_rotation = rotation_degrees
	
	if sprite:
		original_scale = sprite.scale
		original_color = sprite.modulate
		sprite.play("IDDLE")
	
	# Ajustar escala del self según modo hormiga/gigante
	if modo_hormiga:
		scale = scale * 0.5
	elif modo_gigante:
		scale = scale * 1.5
	
	counter_label = get_tree().get_first_node_in_group(counter_group_name) as Label
	if counter_label:
		counter_label.text = "Meters Up: 0"

func _physics_process(delta: float) -> void:
	update_timers(delta)
	apply_gravity(delta)
	handle_horizontal_movement(delta)
	handle_jump(delta)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# Ghost Trail
	update_ghost_trail(delta)
	
	if not was_on_floor and is_on_floor():
		landed = true
		is_jumping = false
		last_jump_was_charged = false
		if jump_buffer_timer > 0:
			execute_jump(min_jump_force)

	apply_air_rotation(delta)
	apply_visual_effects(delta)
	update_counter()

# --- LÓGICA DE TIEMPOS ---
func update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time_duration
	else:
		coyote_timer -= delta
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

# --- MÉTODOS DE MOVIMIENTO ---
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav = gravity * 0.4 if moon_gravity_enabled else gravity
		if gravedad_invertida:
			grav = -grav
		velocity.y += grav * delta

func handle_horizontal_movement(delta: float) -> void:
	var move_input = Input.get_axis("ui_left", "ui_right")
	
	if ice_mode_enabled:
		if move_input != 0:
			velocity.x = lerp(velocity.x, move_input * speed, ice_acceleration * delta)
			if sprite: sprite.flip_h = (move_input > 0)
		else:
			velocity.x = lerp(velocity.x, 0.0, ice_friction * delta)
	else:
		if move_input != 0:
			velocity.x = move_input * speed
			if sprite: sprite.flip_h = (move_input > 0)
		else:
			velocity.x = 0

	if sprite and is_on_floor() and not is_jumping and not is_charging_jump:
		if abs(velocity.x) > 10.0:
			sprite.play("MOVE")
		else:
			sprite.play("IDDLE")

func handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_duration

	if is_on_floor() or coyote_timer > 0:
		if velocity.x == 0 and not ice_mode_enabled:
			if Input.is_action_just_pressed("ui_accept"):
				is_charging_jump = true
				jump_charge = 0.0
			
			if is_charging_jump:
				if Input.is_action_pressed("ui_accept"):
					jump_charge = min(jump_charge + delta, max_charge_time)
				
				if Input.is_action_just_released("ui_accept"):
					var force = lerp(min_jump_force, max_jump_force, jump_charge / max_charge_time)
					if supersaltos:
						force *= 1.8
					if gravedad_invertida:
						force = -force
					if jump_charge > 0.1:
						last_jump_was_charged = true
					execute_jump(force)
					is_charging_jump = false
		elif jump_buffer_timer > 0 and not is_jumping:
			last_jump_was_charged = false
			var force = min_jump_force
			if supersaltos:
				force *= 1.3
			if gravedad_invertida:
				force = -force
			execute_jump(force)

func execute_jump(force: float) -> void:
	var final_force = force * 1.1 if moon_gravity_enabled else force
	velocity.y = final_force
	is_jumping = true
	is_charging_jump = false
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	
	if sprite: sprite.play("JUMP")
	if sonido_jump: sonido_jump.play()

# --- EFECTOS Y JUICE ---
func apply_air_rotation(delta: float) -> void:
	if not is_on_floor():
		# Torque normal en el aire
		angular_acceleration = velocity.x * 0.02
		angular_velocity += angular_acceleration
		angular_velocity *= (1.0 - rotation_friction)
		angular_velocity = clamp(angular_velocity, -max_angular_velocity, max_angular_velocity)
		rotation += angular_velocity * delta
	else:
		if modo_borracho:
			# No se reacomoda automáticamente
			# Simulamos inestabilidad como una botella que tambalea
			var wobble = randf_range(-0.5, 0.5) * delta * 5
			angular_velocity += wobble
			rotation += angular_velocity * delta
			# Le aplicamos un leve freno para que no gire indefinidamente
			angular_velocity *= 0.98
		else:
			# Comportamiento normal: auto-reacomodo
			rotation = lerp_angle(rotation, deg_to_rad(original_rotation), 10 * delta)
			angular_velocity = 0.0
func apply_visual_effects(delta: float) -> void:
	if not sprite: return
	sprite.modulate = original_color.lerp(charge_color, jump_charge / max_charge_time if is_charging_jump else 0.0)

	var target_scale = original_scale
	if modo_hormiga:
		target_scale = original_scale * 0.5
	elif modo_gigante:
		target_scale = original_scale * 1.5
	elif is_charging_jump:
		target_scale = Vector2(original_scale.x + squash_factor, original_scale.y - squash_factor)
	elif is_jumping and velocity.y < 0:
		target_scale = Vector2(original_scale.x - stretch_factor, original_scale.y + stretch_factor)
	elif landed:
		target_scale = Vector2(original_scale.x + squash_factor * 0.8, original_scale.y - squash_factor * 0.8)
		_reset_landed_state()

	sprite.scale = sprite.scale.lerp(target_scale, delta * scale_speed)

func _reset_landed_state() -> void:
	await get_tree().create_timer(0.1).timeout
	landed = false

# --- CONTADOR ---
func update_counter() -> void:
	if position.y < initial_y:
		height_climbed = (initial_y - position.y) / 100.0
	
	var current_value = int(height_climbed)
	if counter_label and current_value != displayed_value:
		displayed_value = current_value
		counter_label.text = "Meters Up: " + str(current_value)
		
		var tween = create_tween()
		tween.tween_property(counter_label, "scale", Vector2(1.3, 1.3), 0.05)
		tween.tween_property(counter_label, "scale", Vector2.ONE, 0.1)

# --- GHOST TRAIL ---
func update_ghost_trail(delta: float) -> void:
	if not ghost_enabled or not sprite: return
	
	var can_spawn = (moon_gravity_enabled or last_jump_was_charged) and not is_charging_jump
	
	if can_spawn and not is_on_floor():
		ghost_timer -= delta
		if ghost_timer <= 0:
			spawn_ghost()
			ghost_timer = ghost_spawn_interval

func spawn_ghost() -> void:
	var ghost = Sprite2D.new()
	ghost.global_position = global_position
	ghost.rotation = rotation
	ghost.scale = scale
	ghost.flip_h = sprite.flip_h
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	
	# Opacidad y color según modo
	var alpha = 0.4
	var color = Color(1,1,1,alpha)
	if moon_gravity_enabled:
		alpha = 0.4
		color = Color(0.6,0.8,1.0,alpha)
	elif last_jump_was_charged:
		alpha = 0.01 + 0.2 * (jump_charge / max_charge_time)
		color = Color(1,0.5,0.5,alpha)
	if rastro_arcoiris:
		color = Color(randf(), randf(), randf(), alpha)

	ghost.modulate = color
	
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, ghost_lifetime)
	tween.tween_callback(ghost.queue_free)
