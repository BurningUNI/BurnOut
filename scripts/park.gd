extends Node2D

@onready var tilemap = $TileMap
@onready var label = $InterazioneLabel
@onready var porta_area = $portaArea
@onready var player: Node2D = $Player
@onready var spawn_room := $SpawnRoom  # Vicino all'ingresso del park

var near_door = false

func _ready() -> void:
	await get_tree().process_frame
	
	if Global.last_exit == "park":
		player.global_position = spawn_room.global_position

	calcola_limiti_mappa()
	label.visible = false

func _process(delta: float) -> void:
	if near_door and Input.is_action_just_pressed("interact"):
		Global.last_exit = "park"
		get_tree().change_scene_to_file("res://scenes/room.tscn")

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
		label.text = "Premi [SPAZIO] per entrare nella stanza"
		label.visible = true

func _on_porta_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label.visible = false
