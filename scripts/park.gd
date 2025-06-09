# park.gd
extends Node2D

@onready var tilemap = $TileMap
@onready var label = $InterazioneLabel
@onready var porta_area = $portaArea
@onready var player: Node2D = $Player
@onready var spawn_room := $SpawnRoom  # Vicino all'ingresso del park

var near_door = false

# Timer per guadagno salute mentale
var salute_timer := 0.0
var guadagno_interval := 12.0  # Ogni 12 secondi reali → 12 minuti gioco

func _ready() -> void:
	await get_tree().process_frame
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	print("🏞️ Park loaded - current_scene_path impostato a:", StatsManager.current_scene_path)
	
	# Musica
	MusicController.play_music(MusicController.track_library["park"], "park")
	
	# Posizione giocatore
	if Global.last_exit == "park":
		player.global_position = spawn_room.global_position

	calcola_limiti_mappa()
	label.visible = false

func _process(delta: float) -> void:
	# Interazione con porta
	if near_door and Input.is_action_just_pressed("interact"):
		Global.last_exit = "park"
		StatsManager.current_scene_path = "res://scenes/room.tscn"
		StatsManager.save_game()
		get_tree().change_scene_to_file("res://scenes/room.tscn")

	# Guadagno salute mentale nel parco
	if player and player.is_inside_tree():
		salute_timer += delta
		if salute_timer >= guadagno_interval:
			salute_timer = 0.0
			if StatsManager.salute_mentale < 100:
				StatsManager.salute_mentale += 1
				StatsManager.emit_signal("salute_mentale_cambiata", StatsManager.salute_mentale)
				print("🌿 Relax al parco: salute mentale +1 →", StatsManager.salute_mentale)

func calcola_limiti_mappa():
	var used_cells = tilemap.get_used_cells(0)
	if used_cells.is_empty():
		print("❌ Nessuna cella trovata nella TileMap.")
		return

	var tile_size = tilemap.tile_set.tile_size
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for cell in used_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)

	var limit_left = min_x * tile_size.x
	var limit_top = min_y * tile_size.y
	var limit_right = (max_x + 1) * tile_size.x
	var limit_bottom = (max_y + 1) * tile_size.y

	print("📐 Limiti mappa TileMap:")
	print("Left: ", limit_left)
	print("Top: ", limit_top)
	print("Right: ", limit_right)
	print("Bottom: ", limit_bottom)

func _on_porta_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true
		label.text = "Premi [SPAZIO] per tornare a casa"
		label.visible = true

func _on_porta_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label.visible = false
