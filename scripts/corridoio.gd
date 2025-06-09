extends Node2D

var current_porta := ""

@onready var label := $InterazioneLabel
@onready var player := $Player
@onready var spawn_porta_casa := $SpawnPortaCasa
@onready var spawn_porta_classe := $SpawnPortaClasse

func _ready() -> void:
	# Registra la scena corrente nel salvataggio
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	MusicController.play_music(MusicController.track_library["school"], "school")
	# Posiziona il giocatore in base all'uscita precedente
	match Global.last_exit:
		"portaCasa":
			player.global_position = spawn_porta_casa.global_position
		"portaClasse":
			player.global_position = spawn_porta_classe.global_position
		_:
			pass  # Posizione di default se non si proviene da una porta nota

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and current_porta != "":
		match current_porta:
			"portaCasa":
				Global.last_exit = "portaCasa"
				StatsManager.current_scene_path = "res://scenes/room.tscn"  # 👈 aggiornamento manuale
				StatsManager.save_game()  # 👈 salvi prima di cambiare scena
				get_tree().change_scene_to_file("res://scenes/room.tscn")
			"portaClasse":
				Global.last_exit = "portaClasse"
				StatsManager.current_scene_path = "res://scenes/classe.tscn"
				StatsManager.save_game()
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
