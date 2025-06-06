extends Node2D

# ---- COSTANTI ORARIO PER DORMIRE ----
const ORA_MINIMA_PER_DORMIRE = 21
const MINUTI_MINIMI_PER_DORMIRE = 30

# ---- VARIABILI DI STATO ----
var near_door = false
var near_bed = false

# ---- NODI ONREADY ----
@onready var stats_manager = get_node("/root/StatsManager")
@onready var letto_label: Label = $LettoLabel
@onready var player: Node2D = $Player
@onready var spawn_room := $SpawnRoom  # Marker2D vicino alla porta d’ingresso

func _ready():
	await get_tree().process_frame

	# --- Posiziona il player se torna dal corridoio ---
	if Global.last_exit == "portaCasa":
		player.global_position = spawn_room.global_position

	# --- Calcolo limiti della mappa ---
	var tilemap_root = $TileMap
	var tile_size := Vector2i(0, 0)
	var all_used_positions: Array[Vector2i] = []

	for child in tilemap_root.get_children():
		if child is TileMapLayer:
			var layer := child
			var used: Array[Vector2i] = layer.get_used_cells()
			if used.size() > 0:
				all_used_positions += used
				if tile_size == Vector2i(0, 0):
					tile_size = layer.tile_set.tile_size

	if all_used_positions.is_empty():
		print("❌ Nessuna cella trovata in nessun layer.")
		return

	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for cell in all_used_positions:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)

	var limit_left = min_x * tile_size.x
	var limit_top = min_y * tile_size.y
	var limit_right = (max_x + 1) * tile_size.x
	var limit_bottom = (max_y + 1) * tile_size.y

	print("📐 Limiti mappa combinati tra tutti i livelli:")
	print("Left: ", limit_left)
	print("Top: ", limit_top)
	print("Right: ", limit_right)
	print("Bottom: ", limit_bottom)

	# --- Collega segnali per il letto (BedArea) ---
	$BedArea.connect("body_entered", _on_bed_area_body_entered)
	$BedArea.connect("body_exited", _on_bed_area_body_exited)


func _process(delta: float) -> void:
	# Porta
	if near_door and Input.is_action_just_pressed("interact"):
		Global.last_exit = "portaCasa"
		get_tree().change_scene_to_file("res://scenes/Corridoio.tscn")

	# Letto
	if near_bed and Input.is_action_just_pressed("interact"):
		tenta_di_dormire()

# ---- INTERAZIONE CON PORTA ----
func _on_door_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true

func _on_door_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false

# ---- INTERAZIONE CON LETTO ----
func _on_bed_area_body_entered(body: Node2D):
	if body.name == "Player":
		near_bed = true
		letto_label.text = "Premi [SPAZIO] per dormire."
		letto_label.visible = true

func _on_bed_area_body_exited(body: Node2D):
	if body.name == "Player":
		near_bed = false
		letto_label.visible = false

# ---- LOGICA DORMIRE ----
func tenta_di_dormire():
	var ora = stats_manager.ora
	var minuti = stats_manager.minuti

	if ora > ORA_MINIMA_PER_DORMIRE or (ora == ORA_MINIMA_PER_DORMIRE and minuti >= MINUTI_MINIMI_PER_DORMIRE):
		stats_manager.ora = 7
		stats_manager.minuti = 0
		stats_manager.giorno += 1
		stats_manager.indice_giorno_settimana = (stats_manager.indice_giorno_settimana + 1) % 7

		stats_manager.emit_signal("tempo_cambiato", stats_manager.ora, stats_manager.minuti, stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana])
		stats_manager.save_game()

		letto_label.text = "Hai dormito bene! Nuovo giorno: %s Giorno %d" % [
			stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana],
			stats_manager.giorno
		]
	else:
		letto_label.text = "È troppo presto per andare a dormire! Riprova dopo le %02d:%02d." % [ORA_MINIMA_PER_DORMIRE, MINUTI_MINIMI_PER_DORMIRE]

	letto_label.visible = true
