extends Node2D

var current_porta := ""
@onready var label := $InterazioneLabel
@onready var player := $Player
@onready var spawn_porta_casa := $SpawnPortaCasa
@onready var spawn_porta_classe := $SpawnPortaClasse

func _ready() -> void:
	match Global.last_exit:
		"portaCasa":
			player.global_position = spawn_porta_casa.global_position
		"portaClasse":
			player.global_position = spawn_porta_classe.global_position
		_:
			pass  # posizione di default

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and current_porta != "":
		match current_porta:
			"portaCasa":
				Global.last_exit = "portaCasa"
				get_tree().change_scene_to_file("res://scenes/room.tscn")
			"portaClasse":
				Global.last_exit = "portaClasse"
				get_tree().change_scene_to_file("res://scenes/classe.tscn")

func _on_porta_casa_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = "portaCasa"
		label.text = "Premi SPAZIO per tornare a casa"
		label.visible = true

func _on_porta_casa_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = ""
		label.visible = false

func _on_porta_classe_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = "portaClasse"
		label.text = "Premi SPAZIO per entrare in classe"
		label.visible = true

func _on_porta_classe_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = ""
		label.visible = false
