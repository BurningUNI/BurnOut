extends Node2D

var near_door = false
@onready var label := $InterazioneLabel

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if near_door and Input.is_action_just_pressed("interact"):
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
