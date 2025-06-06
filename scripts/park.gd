extends Node2D

@onready var tilemap = $TileMap

func _ready() -> void:
	calcola_limiti_mappa()

func _process(delta: float) -> void:
	pass

func calcola_limiti_mappa():
	var used_cells = tilemap.get_used_cells(0)  # Layer 0
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
