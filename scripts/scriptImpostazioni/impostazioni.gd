extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_indietro_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")


func _on_indietro_mouse_entered() -> void:
	MusicController.play_hover_sound()


func _on_crediti_buttons_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/credits.tscn")


func _on_crediti_buttons_mouse_entered() -> void:
	MusicController.play_hover_sound()
