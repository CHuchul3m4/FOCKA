extends Node2D

@export var sky_rect: ColorRect
@export var canvas: CanvasModulate

# 🌤️ Colores del cielo
var day_color = Color(0.5, 0.8, 1.0)
var afternoon_color = Color(1.0, 0.5, 0.3)
var night_color = Color(0.0, 0.0, 0.2)
var dawn_color = Color(0.4, 0.2, 0.6)

# 🎨 CanvasModulate
var day_canvas_color = Color(1.0, 1.0, 1.0)
var night_canvas_color = Color(0.02, 0.02, 0.02)

# ⏱️ Duraciones
var time_scale = 300.0

var durations = {
	"day": 120.0,
	"afternoon": time_scale,
	"night": 120.0,
	"dawn": 120.0
}

# Estado actual
var current_phase: String

func _ready():
	set_initial_state()
	start_cycle_loop()

# 🔹 Solo se usa UNA vez
func set_initial_state():
	var time = Time.get_time_dict_from_system()
	var hour = time.hour

	if hour >= 6 and hour < 12:
		current_phase = "day"
		sky_rect.color = day_color
		canvas.color = day_canvas_color

	elif hour >= 12 and hour < 19:
		current_phase = "afternoon"
		sky_rect.color = afternoon_color
		canvas.color = day_canvas_color

	elif hour >= 19 or hour < 4:
		current_phase = "night"
		sky_rect.color = night_color
		canvas.color = night_canvas_color

	elif hour >= 4 and hour < 6:
		current_phase = "dawn"
		sky_rect.color = dawn_color
		canvas.color = day_canvas_color

# 🔁 Loop infinito independiente del sistema
func start_cycle_loop():
	while true:
		match current_phase:

			"day":
				await transition(
					day_color, afternoon_color,
					day_canvas_color, day_canvas_color,
					durations["day"]
				)
				current_phase = "afternoon"

			"afternoon":
				await transition(
					afternoon_color, night_color,
					day_canvas_color, night_canvas_color,
					durations["afternoon"]
				)
				current_phase = "night"

			"night":
				await transition(
					night_color, dawn_color,
					night_canvas_color, day_canvas_color,
					durations["night"]
				)
				current_phase = "dawn"

			"dawn":
				await transition(
					dawn_color, day_color,
					day_canvas_color, day_canvas_color,
					durations["dawn"]
				)
				current_phase = "day"

# 🎬 Transición con Tween (Godot 4)
func transition(
	from_sky_color: Color,
	to_sky_color: Color,
	from_canvas_color: Color,
	to_canvas_color: Color,
	duration: float
) -> void:

	var tween = create_tween()
	var tween_canvas = create_tween()

	tween.tween_property(sky_rect, "color", to_sky_color, duration).from(from_sky_color)
	tween_canvas.tween_property(canvas, "color", to_canvas_color, duration).from(from_canvas_color)

	await tween.finished
	await tween_canvas.finished
