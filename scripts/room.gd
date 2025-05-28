extends Node2D

func _ready():
	# Ottieni un riferimento al tuo TileMap
	var tilemap = $TileMap

	# Ottieni un riferimento alla tua Camera2D.
	# Il percorso è '$Player/Camera2D' perché il nodo Player è un figlio diretto
	# del nodo Room, e Camera2D è un figlio diretto del nodo Player.
	var cam = $Player/Camera2D

	# Assicurati che cam sia stato trovato, altrimenti stampa un errore e ferma l'esecuzione.
	if cam == null:
		print("Errore: Camera2D non trovata al percorso '$Player/Camera2D'. Controlla la tua scena.")
		return # Esce dalla funzione _ready() se la camera non è stata trovata

	# Ottieni il rettangolo utilizzato dal TileMap e la dimensione delle tile
	var map_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size


	# Limiti orizzontali
	cam.limit_left = map_rect.position.x * tile_size.x
	cam.limit_right = (map_rect.position.x + map_rect.size.x) * tile_size.x

	# Blocchiamo il movimento verticale forzando il valore Y
	var camera_start_y = cam.global_position.y
	cam.limit_top = camera_start_y
	cam.limit_bottom = camera_start_y

	cam.set_as_top_level(true)


	if $Player: # Controlla che il nodo Player esista
		cam.global_position = $Player.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_bed_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
