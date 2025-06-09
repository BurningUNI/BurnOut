extends Node2D

var near_door = false
@onready var label := $InterazioneLabel

func _ready() -> void:
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	MusicController.play_music(MusicController.track_library["school"], "school")
func _process(delta: float) -> void:
	if near_door and Input.is_action_just_pressed("interact"):
		Global.last_exit = "classe"
		StatsManager.current_scene_path = "res://scenes/Corridoio.tscn"
		StatsManager.save_game()
		get_tree().change_scene_to_file("res://scenes/Corridoio.tscn")


func _on_area_porta_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true
		label.text = "Premi SPAZIO per tornare nel corridoio"
		label.visible = true

func _on_area_porta_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label.visible = false
