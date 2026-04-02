extends Node2D
@onready var Animatorplayer = $UI/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if Input.is_action_just_pressed("UI_CLICK"):
		fadeout()

func _on_timer_timeout() -> void:
	fadeout()

func fadeout() -> void:
	Animatorplayer.play("Fade-Out")
func cambiar_escena():
	get_tree().change_scene_to_file("res://Escenas/MENU.tscn")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fade-Out":
		cambiar_escena()
