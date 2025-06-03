# SelezionaPartita.gd
extends Control

@onready var continua_partita_button = $VBoxContainer/ContinuaPartitaButton as Button
@onready var giorno_label = $VBoxContainer/Stats/GiornoLabel as Label
@onready var soldi_label = $VBoxContainer/Stats/SoldiLabel as Label
@onready var salute_mentale_label = $VBoxContainer/Stats/SaluteMentaleLabel as Label
@onready var nuova_partita_button = $VBoxContainer/NuovaPartitaButton as Button
@onready var indietro_button = $VBoxContainer/IndietroButton as Button

@onready var game_state: Node = get_node("/root/GameState") # Riferimento al tuo Autoload GameState

# Precarica le scene necessarie
@onready var intro_scene = preload("res://scenes/letteraIniziale.tscn") as PackedScene
@onready var game_scene = preload("res://scenes/room.tscn") as PackedScene
func _ready():
	update_continue_button_state()
	update_stats_labels()

func update_continue_button_state():
	continua_partita_button.disabled = not FileAccess.file_exists(game_state.SAVE_PATH)

func update_stats_labels():
	if FileAccess.file_exists(game_state.SAVE_PATH):
		var save_data = load_save_data()
		if save_data:
			giorno_label.text = "Giorno: %d" % save_data.giorno
			soldi_label.text = "Soldi: %d" % save_data.soldi
			salute_mentale_label.text = "Salute Mentale: %d%%" % save_data.salute_mentale
		else:
			giorno_label.text = "Nessun salvataggio valido"
			soldi_label.text = ""
			salute_mentale_label.text = ""
	else:
		giorno_label.text = "Nessun salvataggio trovato"
		soldi_label.text = ""
		salute_mentale_label.text = ""

class SaveData:
	var giorno: int
	var soldi: int
	var salute_mentale: int

func load_save_data() -> SaveData:
	if not FileAccess.file_exists(game_state.SAVE_PATH):
		return null

	var file = FileAccess.open(game_state.SAVE_PATH, FileAccess.READ)
	if file == null:
		print("Errore nell'apertura del file per lettura in SelezionaPartita:", FileAccess.get_open_error())
		return null

	var content = file.get_as_text()
	file.close()

	var json_parsed = JSON.parse_string(content)
	if json_parsed == null:
		print("Errore nel parsing JSON del file di salvataggio in SelezionaPartita.")
		return null

	var save_data = SaveData.new()
	save_data.giorno = int(json_parsed.get("giorno", 1))
	save_data.soldi = int(json_parsed.get("soldi", 500))
	save_data.salute_mentale = int(json_parsed.get("salute_mentale", 100))
	return save_data



func _on_nuova_partita_button_pressed() -> void:
	MusicController.play_click_sound()
	game_state.salute_mentale = 100
	game_state.soldi = 500
	game_state.ora = 11
	game_state.minuti = 30
	game_state.giorno = 1
	game_state.indice_giorno_settimana = 0

	game_state.save_game()

	get_tree().change_scene_to_packed(intro_scene)


func _on_nuova_partita_button_mouse_entered() -> void:
	MusicController.play_hover_sound()


func _on_continua_partita_button_pressed() -> void:
	MusicController.play_click_sound()
	if game_state.load_game():
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("Errore critico nel caricamento della partita salvata. Non è stato possibile caricare il gioco.")
		continua_partita_button.disabled = true 


func _on_continua_partita_button_mouse_entered() -> void:
	MusicController.play_hover_sound()


func _on_indietro_button_pressed() -> void:
	MusicController.play_click_sound()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	
func _on_indietro_button_mouse_entered() -> void:
	MusicController.play_hover_sound()
