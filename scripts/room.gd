extends Node2D

func _ready():
	var tilemap = $TileMap
	var cam = $Player/Camera2D

	var map_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size

	# Limiti orizzontali
	cam.limit_left = map_rect.position.x * tile_size.x
	cam.limit_right = (map_rect.position.x + map_rect.size.x) * tile_size.x

	# Blocchiamo il movimento verticale forzando il valore Y
	var camera_start_y = cam.global_position.y
	cam.limit_top = camera_start_y
	cam.limit_bottom = camera_start_y



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
