extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicController.play_music(MusicController.track_library["win"], "win", false)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_button_pressed() -> void:
	StatsManager.resetta_statistiche()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
