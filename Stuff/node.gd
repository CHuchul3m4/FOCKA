extends Node

func _ready() -> void:
	# Buscamos todas las zonas de hielo en la escena y nos conectamos a ellas
	var zonas_hielo = get_tree().get_nodes_in_group("ICE")
	
	for hielo in zonas_hielo:
		if hielo is Area2D:
			# Conectamos la señal de cuando algo entra al hielo
			hielo.body_entered.connect(_on_hielo_body_entered)
			# Conectamos la señal de cuando algo sale del hielo
			hielo.body_exited.connect(_on_hielo_body_exited)

# Cuando cualquier cuerpo (body) entra al hielo
func _on_hielo_body_entered(body: Node2D) -> void:
	# ¿El cuerpo que entró pertenece al grupo Player?
	if body.is_in_group("Player") and "ice_mode_enabled" in body:
		body.ice_mode_enabled = true

# Cuando cualquier cuerpo sale del hielo
func _on_hielo_body_exited(body: Node2D) -> void:
	# ¿El cuerpo que salió pertenece al grupo Player?
	if body.is_in_group("Player") and "ice_mode_enabled" in body:
		body.ice_mode_enabled = false
