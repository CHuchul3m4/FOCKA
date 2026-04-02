extends Camera2D

var shake_amount: float = 0
var shake_amout_Handheld: float = 0
var default_offset: Vector2
@onready var timer: Timer = $Timer
var noise := FastNoiseLite.new()
var noise_time: float = 0
var handheld_active: bool = false
var shaking: bool = false

func _ready() -> void:
	default_offset = offset
	set_process(false)
	Global.camera = self
	randomize()
	noise.seed = randi()
	noise.set_fractal_octaves(4)
	noise.frequency = 1.0 / 20.0
	noise.set_fractal_gain(0.8)

func _process(delta: float) -> void:
	var shake_offset = Vector2.ZERO
	var handheld_offset = Vector2.ZERO

	if shaking:
		shake_offset = Vector2(randf_range(-1, 1) * shake_amount, randf_range(-1, 1) * shake_amount)

	if handheld_active:
		noise_time += delta
		handheld_offset.x = noise.get_noise_1d(noise_time * 10) * shake_amout_Handheld
		handheld_offset.y = noise.get_noise_1d(noise_time * 10 + 1000) * shake_amout_Handheld

	offset = shake_offset + handheld_offset

func shake(time: float, amount: float) -> void:
	shake_amount = amount
	shaking = true
	timer.wait_time = time
	timer.start()
	set_process(true)

func _on_Timer_timeout() -> void:
	shaking = false
	shake_amount = 0
	if not handheld_active:
		set_process(false)

func start_handheld(amount_H: float) -> void:
	shake_amout_Handheld = amount_H
	handheld_active = true
	set_process(true)

func stop_handheld() -> void:
	handheld_active = false
	shake_amout_Handheld = 0
	if not shaking:
		set_process(false)
	offset = default_offset
