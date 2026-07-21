extends Node2D

# --- CONFIGURACIÓN DEL NIVEL EN EL INSPECTOR ---

## Cantidad total de tiles que tendrá el nivel en su totalidad.
@export var total_tiles: int = 3

## El nodo contenedor donde se van a meter los tiles hijos. 
## Si se deja vacío en el inspector, por defecto usará este mismo script (_ready).
@export var mapa_contenedor: Node2D

## La altura en píxeles de cada tile. Sirve para calcular la distancia 
## que debemos movernos hacia arriba al colocar el siguiente tile.
@export var tile_height: float = 150.0


# --- POOLS DE ESCENAS (TILES) POR FASES ---

## Lista de escenas (PackedScene) disponibles para la Fase 1 (Zona Inferior/Inicio).
@export var fase_1_tiles: Array[PackedScene] = [
	preload("res://PROCEDURAL/Tiles/1/ground_1.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_2.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_3.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_4.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_5.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_6.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_7.tscn"),
	preload("res://PROCEDURAL/Tiles/1/ground_8.tscn")] 

## Lista de escenas disponibles para la Fase 2 (Zona Media/Transición).
@export var fase_2_tiles: Array[PackedScene] = [
	preload("res://PROCEDURAL/Tiles/2/ground2_1.tscn"),
	preload("res://PROCEDURAL/Tiles/2/ground2_2.tscn"),
	preload("res://PROCEDURAL/Tiles/2/ground2_3.tscn"),
	preload("res://PROCEDURAL/Tiles/2/ground2_4.tscn")]

## Lista de escenas disponibles para la Fase 3 (Zona Superior/Final).
@export var fase_3_tiles: Array[PackedScene] = [
	preload("res://PROCEDURAL/Tiles/3/ground3_1.tscn"),
	preload("res://PROCEDURAL/Tiles/3/ground3_2.tscn"),
	preload("res://PROCEDURAL/Tiles/3/ground3_3.tscn")
	]


# --- FUNCIÓN PRINCIPAL DE INICIALIZACIÓN ---

func _ready() -> void:
	# Seguridad: Si no asignaste un contenedor en el inspector, 
	# el script se asigna a sí mismo como el contenedor padre.
	if mapa_contenedor == null:
		mapa_contenedor = self
	
	# Arranca la generación procedimental del mapa
	generar_nivel()


# --- LÓGICA DE GENERACIÓN PROCEDIMENTAL ---

func generar_nivel():
	# Divide el total de tiles entre 3 fases y redondea hacia abajo (floor).
	# Ej: Si total_tiles es 17 -> 17 / 3 = 5.66 -> tiles_por_fase será 5.
	var tiles_por_fase: int = floor(total_tiles / 3.0)
	
	# Variable que controla la coordenada Y donde se spawneará el próximo tile.
	# Empezamos en el origen (0.0).
	var spawn_pos_y: float = 0.0
	
	# Bucle principal que se ejecuta tantas veces como tiles totales queramos
	for i in range(total_tiles):
		# Variable temporal para guardar la instancia del tile actual
		var nueva_parte: Node2D
		
		# --- SELECCIÓN DE FASE SEGÚN EL ÍNDICE 'i' ---
		
		if i < tiles_por_fase:
			# FASE 1: Se ejecuta desde i = 0 hasta i < tiles_por_fase.
			# .pick_random() elige un tile al azar del array y .instantiate() lo crea en memoria.
			nueva_parte = fase_1_tiles.pick_random().instantiate()
			
		elif i < tiles_por_fase * 2:
			# FASE 2: Se ejecuta en el segundo bloque de tiles.
			# Ej: Si tiles_por_fase es 5, entrará aquí desde i = 5 hasta i < 10.
			nueva_parte = fase_2_tiles.pick_random().instantiate()
			
		else:
			# FASE 3: El último bloque. 
			# Nota: Absorbe cualquier residuo/resto de la división decimal (el sobrante).
			nueva_parte = fase_3_tiles.pick_random().instantiate()
		
		# --- INSTANCIACIÓN Y POSICIONAMIENTO ---
		
		# Añade el tile recién creado como hijo del nodo contenedor para que aparezca en el juego.
		mapa_contenedor.add_child(nueva_parte)
		
		# Asigna la posición en el espacio 2D. X se queda en 0 y Y usa la variable acumuladora.
		nueva_parte.position = Vector2(0, spawn_pos_y)
		
		# IMPORTANTE: En Godot, el eje -Y apunta hacia ARRIBA.
		# Restamos la altura para que el próximo tile se dibuje encima del actual.
		spawn_pos_y -= tile_height
