# GameManager.gd
extends Node

# Definisce il percorso della tua scena di Game Over.
# !!! IMPORTANTE: Assicurati che questo percorso sia ESATTO !!!
const GAME_OVER_SCENE_PATH = "res://scenes/gameOver.tscn" 

func _ready():
	var stats_manager = get_node_or_null("/root/StatsManager")

	if stats_manager:

		stats_manager.game_over_salute_mentale.connect(self._on_game_over_salute_mentale)
		print("GameManager: Connesso al segnale 'game_over_salute_mentale' di StatsManager.")
	else:

		push_error("ERRORE: StatsManager non trovato come Autoload. La gestione del Game Over potrebbe non funzionare correttamente.")

# Questa funzione viene chiamata automaticamente quando il segnale 'game_over_salute_mentale' viene emesso.
func _on_game_over_salute_mentale():
	print("GameManager: Ricevuto segnale GAME OVER: la salute mentale è esaurita!")

	if FileAccess.file_exists(GAME_OVER_SCENE_PATH):
		# Cambia la scena corrente alla scena di Game Over.
		get_tree().change_scene_to_file(GAME_OVER_SCENE_PATH)
		print("GameManager: Caricamento scena Game Over completato: ", GAME_OVER_SCENE_PATH)
	else:
		# Se il percorso della scena è sbagliato, riceverai questo errore.
		push_error("ERRORE: La scena di Game Over non è stata trovata al percorso: " + GAME_OVER_SCENE_PATH)
		print("GameManager: Impossibile caricare la scena di Game Over. Controlla il percorso!")
