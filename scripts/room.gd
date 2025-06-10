#room
extends Node2D

# ---- COSTANTI ORARIO PER DORMIRE ----
const ORA_MINIMA_PER_DORMIRE = 21
const MINUTI_MINIMI_PER_DORMIRE = 30

# Orario limite massimo per andare a dormire al mattino (escluso)
# Significa che si può dormire fino alle 06:59, ma non dalle 07:00 in poi per "ricominciare il giorno".
const ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA = 7

# NUOVA COSTANTE: Quantità di salute mentale recuperata dormendo
const RECUPERO_SALUTE_MENTALE_DORMIRE = 25# Recupera 25 punti salute mentale

# ---- COSTANTI PER I LIMITI DI STUDIO ----
# Ora di inizio delle penalità (21:00)
const ORA_INIZIO_PENALTY_STUDIO = 21
const MINUTI_INIZIO_PENALTY_STUDIO = 0

# Orario di inizio e fine della "notte profonda" (es. dalle 00:00 alle 05:59)
# durante la quale non è mai permesso studiare.
const ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO = 0
const ORA_FINE_BLOCCO_NOTTURNO_STUDIO = 6

# ---- COSTANTI PER EVENTI DI STUDIO CASUALI ----
# Probabilità che si verifichi un evento casuale durante lo studio (es. 0.3 = 30%)
const PROBABILITA_EVENTO_STUDIO = 0.3
# Lista di eventi casuali che possono accadere durante lo studio
const EVENTI_STUDIO = [
	{"tipo": "positivo", "messaggio": "Hai avuto un'illuminazione! Studio extra!", "mental_health_mod": 5, "study_mod": 10},
	{"tipo": "negativo", "messaggio": "Distrazione! La tua sessione di studio ne risente.", "mental_health_mod": -10, "study_mod": -5},
	{"tipo": "positivo", "messaggio": "Hai trovato un ottimo riassunto online! Apprendimento accelerato.", "mental_health_mod": 0, "study_mod": 7},
	{"tipo": "negativo", "messaggio": "Ti senti esausto, studiare è più difficile.", "mental_health_mod": -15, "study_mod": -3},
	{"tipo": "positivo", "messaggio": "Sei super concentrato! Studio eccezionale.", "mental_health_mod": 3, "study_mod": 12},
	{"tipo": "negativo", "messaggio": "Problemi tecnici col computer! Perdi tempo prezioso.", "mental_health_mod": -7, "study_mod": -4}
]


# ---- VARIABILI DI STATO ----
var near_door = false # Vero se il giocatore è vicino alla porta
var near_bed = false# Vero se il giocatore è vicino al letto
var near_desk = false # Vero se il giocatore è vicino alla scrivania

# ---- NODI ONREADY (Collegamento automatico dei nodi dalla scena) ----
@onready var stats_manager = get_node("/root/StatsManager") # Manager globale delle statistiche
@onready var letto_label: Label = $BedArea/LettoLabel# Etichetta di interazione con il letto
@onready var player: Node2D = $Player# Nodo del giocatore
@onready var spawn_room := $SpawnRoom# Punto di spawn del giocatore nella stanza
@onready var label_interazione: Label = $DoorArea/InterazioneLabel# Etichetta di interazione con la porta
@onready var popup_uscita = $SceltaUscita# Popup per la scelta dell'uscita
@onready var button_corridoio = $SceltaUscita/VBoxContainer/ButtonCorridoio # Bottone per andare al corridoio
@onready var button_park = $SceltaUscita/VBoxContainer/ButtonPark# Bottone per andare al parco

# NODI ONREADY PER LA SCRIVANIA
@onready var desk_area: Area2D = $DeskArea# Area di rilevamento della scrivania
@onready var desk_interazione_label: Label = $DeskArea/InterazioneLabel # Etichetta di interazione con la scrivania
@onready var popup_studio = $DeskArea/PopupStudio# Popup per la scelta della materia di studio
@onready var analisi_bottone = $DeskArea/PopupStudio/VBoxContainer/AnalisiBottone# Bottone per studiare Analisi
@onready var programmazione_bottone = $DeskArea/PopupStudio/VBoxContainer/ProgrammazioneBottone #Bottone per studiare Programmazione
@onready var studio_label: Label = $DeskArea/PopupStudio/VBoxContainer/studioLabel#Etichetta del popup di studio

func _ready():
	# Attendi un frame per assicurarti che tutti i nodi siano pronti
	await get_tree().process_frame
	
	# Avvia la musica di sottofondo per la stanza
	MusicController.play_music(MusicController.track_library["room"], "room")
	
	# Aggiorna il percorso della scena corrente nel StatsManager
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	
	# Se il giocatore arriva dalla porta di casa o dal parco, posizionalo allo spawn della stanza
	if Global.last_exit == "portaCasa" or Global.last_exit == "park":
		player.global_position = spawn_room.global_position

	# Calcola i limiti della mappa (utile per la telecamera o altri scopi)
	calcola_limiti_mappa()
	# Imposta la visibilità iniziale delle label e dei popup
	label_interazione.visible = false
	letto_label.visible = false
	popup_uscita.hide() # Nasconde il popup di uscita all'avvio
	
	desk_interazione_label.visible = false
	popup_studio.hide() # Nasconde il popup di studio all'avvio

	# Imposta il testo dei pulsanti di uscita e collega le funzioni
	button_corridoio.text = "Vai in università"
	button_park.text = "Vai al parco"
	button_corridoio.pressed.connect(_vai_al_corridoio)
	button_park.pressed.connect(_vai_al_parco)


func _process(_delta: float) -> void:
	# Gestisce le interazioni con la pressione del tasto "interact" (SPAZIO)
	if Input.is_action_just_pressed("interact"):
		if near_door and not popup_uscita.visible:
			# Se vicino alla porta e il popup di uscita non è visibile, mostralo
			popup_uscita.popup_centered()
		elif near_bed:
			# Se vicino al letto, tenta di dormire
			tenta_di_dormire()
		elif near_desk and not popup_studio.visible:
			# Se vicino alla scrivania e il popup di studio non è visibile, gestisci l'interazione di studio
			handle_study_interaction()

# ---- FUNZIONE AUSILIARIA PER I MESSAGGI DI INTERAZIONE ----
# Mostra un messaggio temporaneo sull'etichetta di interazione della scrivania
func display_interaction_message(message: String, duration: float = 3.0) -> void:
	desk_interazione_label.text = message
	desk_interazione_label.visible = true
	desk_interazione_label.modulate.a = 1.0 # Assicurati che sia completamente visibile all'inizio
	var tween = create_tween() # Crea un tween per far svanire l'etichetta
	tween.tween_interval(duration) # Attendi la durata specificata
	tween.tween_property(desk_interazione_label, "modulate:a", 0.0, 1.0) # Svanisci l'opacità a 0
	tween.finished.connect(func(): # Quando il tween è finito
		desk_interazione_label.visible = false # Nascondi l'etichetta
		desk_interazione_label.modulate.a = 1.0 # Resetta l'opacità per il prossimo uso
	)

# ---- INTERAZIONE CON LA PORTA ----
func _on_door_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true
		label_interazione.text = "Premi [SPAZIO] per uscire di casa"
		label_interazione.visible = true

func _on_door_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label_interazione.visible = false
		popup_uscita.hide() # Nascondi il popup di uscita se il giocatore si allontana

func _vai_al_corridoio():
	Global.last_exit = "portaCasa" # Salva l'ultima uscita per lo spawn nella prossima scena
	stats_manager.current_scene_path = "res://scenes/Corridoio.tscn" # Imposta la prossima scena
	stats_manager.save_game() # Salva lo stato del gioco
	get_tree().change_scene_to_file("res://scenes/Corridoio.tscn") # Cambia scena

func _vai_al_parco():
	Global.last_exit = "park" # Salva l'ultima uscita
	stats_manager.current_scene_path = "res://scenes/Park.tscn" # Imposta la prossima scena
	stats_manager.save_game() # Salva lo stato del gioco
	get_tree().change_scene_to_file("res://scenes/Park.tscn") # Cambia scena

# ---- INTERAZIONE CON IL LETTO ----
func _on_bed_area_body_entered(body: Node2D):
	if body.name == "Player":
		near_bed = true
		letto_label.text = "Premi [SPAZIO] per dormire."
		letto_label.visible = true

func _on_bed_area_body_exited(body: Node2D):
	if body.name == "Player":
		near_bed = false
		letto_label.visible = false

func tenta_di_dormire():
	var ora = stats_manager.ora
	var minuti = stats_manager.minuti

	var sleep_successful = false
	var message = ""

	# Condizione 1: dormi di sera (es. 21:30 - 23:59)
	if (ora > ORA_MINIMA_PER_DORMIRE or (ora == ORA_MINIMA_PER_DORMIRE and minuti >= MINUTI_MINIMI_PER_DORMIRE)) and ora <= 23:
		stats_manager.giorno += 1
		stats_manager.indice_giorno_settimana = (stats_manager.indice_giorno_settimana + 1) % 7
		sleep_successful = true
		message = "Hai dormito bene! Nuovo giorno: %s Giorno %d" % [
			stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana],
			stats_manager.giorno
		]

	# Condizione 2: dormi dopo mezzanotte (es. 00:00 - 06:59)
	elif ora >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora < ORA_FINE_PERIODO_SONNO_MATTINO_ESCLUSA:
		sleep_successful = true
		message = "Hai dormito bene! Continua il %s Giorno %d" % [
			stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana],
			stats_manager.giorno
		]
	else:
		message = "Non è l'orario giusto per dormire. Puoi dormire dalle %02d:%02d" % [
			ORA_MINIMA_PER_DORMIRE, MINUTI_MINIMI_PER_DORMIRE
		]

	if sleep_successful:
		stats_manager.ora = 7
		stats_manager.minuti = 0
		stats_manager.aumenta_salute_mentale(RECUPERO_SALUTE_MENTALE_DORMIRE)
		message += "\nHai recuperato %d punti di salute mentale!" % RECUPERO_SALUTE_MENTALE_DORMIRE
		stats_manager.save_game()

		# 🟨 Se è il giorno dell'esame (15), decidi cosa fare
		if stats_manager.giorno == 15:
			if stats_manager.statoAnalisi >= 60 and stats_manager.statoProgrammazione >= 60:
				stats_manager.current_scene_path = "res://Scenes/dialogo.tscn"
				get_tree().change_scene_to_file("res://Scenes/dialogo.tscn")
				return
			else:
				stats_manager.current_scene_path = "res://Scenes/gameOver.tscn"
				get_tree().change_scene_to_file("res://Scenes/gameOver.tscn")
				return

	letto_label.text = message
	letto_label.visible = true


# ---- GESTIONE INTERAZIONE DI STUDIO ----
func handle_study_interaction():
	var ora_attuale = stats_manager.ora
	
	# Controlla se è nella fascia oraria di blocco notturno (00:00 - 05:59)
	var is_night_block = (ora_attuale >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora_attuale < ORA_FINE_BLOCCO_NOTTURNO_STUDIO)

	if is_night_block:
		display_interaction_message("È troppo tardi per studiare! Devi aspettare il giorno.")
	else:
		# Se non è nella fascia notturna, mostra il popup di studio
		popup_studio.popup_centered()

# ---- INTERAZIONE CON LA SCRIVANIA (BOTTONI) ----
func _on_desk_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_desk = true
		desk_interazione_label.text = "Premi [SPAZIO] per studiare"
		desk_interazione_label.visible = true

func _on_desk_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_desk = false
		desk_interazione_label.visible = false
		popup_studio.hide() # Nascondi il popup se il player si allontana

func _on_analisi_bottone_pressed():
	studia("analisi") # Chiama la funzione studia per "analisi"

func _on_programmazione_bottone_pressed():
	studia("programmazione") # Chiama la funzione studia per "programmazione"

func studia(materia: String):
	# Chiudi il popup di studio
	popup_studio.hide()

	var ora_attuale = stats_manager.ora

	if (ora_attuale >= ORA_INIZIO_BLOCCO_NOTTURNO_STUDIO and ora_attuale < ORA_FINE_BLOCCO_NOTTURNO_STUDIO):
		display_interaction_message("È troppo tardi per studiare! Devi aspettare il giorno.")
		return # Interrompe l'esecuzione della funzione qui

	# Controlla se la materia ha già raggiunto il livello massimo (100)
	if (materia == "analisi" and stats_manager.statoAnalisi >= 100) or \
	   (materia == "programmazione" and stats_manager.statoProgrammazione >= 100):
		display_interaction_message("Hai già raggiunto il livello massimo in %s! Non puoi studiare oltre." % materia.capitalize())
		return # Interrompe l'esecuzione se lo studio è al massimo

	var mental_health_loss = 10 # Perdita base di salute mentale
	var study_gain = 3
	var study_message = ""

	# Controlla per le penalità (dalle 21:00 in poi, fino alle 23:59)
	if ora_attuale >= ORA_INIZIO_PENALTY_STUDIO:
		mental_health_loss = 15 # Aumenta la perdita di salute mentale
		study_gain = 2# Diminuisce il guadagno di studio
		study_message = " Hai studiato fino a tardi!" # Messaggio per studio notturno
	else:
		study_message = " Hai studiato bene!" # Messaggio per studio normale

	# Fai passare 4 ore di gioco
	stats_manager.avanza_ore(4)

	# Riduci la salute mentale del giocatore
	stats_manager.diminuisci_salute_mentale(mental_health_loss)

	# Aumenta lo stato di studio della materia scelta
	stats_manager.aumenta_stato_studio(materia, study_gain)

	print("Hai studiato %s per 4 ore. Salute mentale ridotta di %d. Stato studio aumentato di %d." % [materia, mental_health_loss, study_gain])
	print("Stato Analisi:", stats_manager.statoAnalisi)
	print("Stato Programmazione:", stats_manager.statoProgrammazione)
	
	var final_message = "Hai studiato %s per 4 ore!%s" % [materia, study_message]

	# ---- Gestione evento casuale di studio ----
	# Controlla se deve accadere un evento casuale (basato sulla probabilità)
	if randf() < PROBABILITA_EVENTO_STUDIO:
		# Scegli un evento casuale dalla lista EVENTI_STUDIO
		var event_data = EVENTI_STUDIO[randi() % EVENTI_STUDIO.size()]
		
		# Applica le modifiche alla salute mentale (mental_health_mod può essere negativo per aumentare)
		stats_manager.diminuisci_salute_mentale(-event_data.mental_health_mod)
		# Applica le modifiche allo stato di studio (study_mod può essere negativo per diminuire)
		stats_manager.aumenta_stato_studio(materia, event_data.study_mod)
		
		# Aggiungi il messaggio dell'evento al messaggio finale
		final_message += "\n" + event_data.messaggio

	# Mostra il messaggio finale di interazione (con eventuali eventi casuali)
	display_interaction_message(final_message)


# ---- CALCOLO LIMITI MAPPA (per la telecamera o il movimento del giocatore) ----
func calcola_limiti_mappa():
	var tilemap_root = $TileMap # Nodo principale che contiene i TileMap
	var tile_size := Vector2i(0, 0) # Dimensione delle tile (cella)
	var all_used_positions: Array[Vector2i] = [] # Lista di tutte le posizioni delle celle usate

	# Itera su tutti i figli del nodo TileMap principale
	for child in tilemap_root.get_children():
		# Se il figlio è un TileMap (scenario più comune in Godot 4)
		if child is TileMap:
			var tilemap_node: TileMap = child
			# Itera su tutti i layer del TileMap
			for layer_index in range(tilemap_node.get_layers_count()):
				# Ottieni le celle usate in questo layer
				var used: Array[Vector2i] = tilemap_node.get_used_cells(layer_index)
				if used.size() > 0:
					# Aggiungi le celle usate alla lista generale
					all_used_positions.append_array(used)
					# Se la dimensione della tile non è ancora impostata, prendila dal TileSet
					if tile_size == Vector2i(0, 0) and tilemap_node.tile_set:
						tile_size = tilemap_node.tile_set.tile_size
		# Se il figlio è un TileMapLayer (per progetti più vecchi o configurazioni specifiche)
		elif child is TileMapLayer:
			var layer := child
			var used: Array[Vector2i] = layer.get_used_cells()
			if used.size() > 0:
				all_used_positions.append_array(used)
				if tile_size == Vector2i(0, 0) and layer.tile_set:
					tile_size = layer.tile_set.tile_size


	# Se non sono state trovate celle usate, stampa un avviso
	if all_used_positions.is_empty():
		print("❌ Nessuna cella trovata in nessun layer. I limiti della mappa potrebbero non essere calcolati correttamente.")
		return

	# Inizializza i valori minimi e massimi per X e Y con valori infiniti/negativi
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	# Trova le coordinate minime e massime tra tutte le celle usate
	for cell in all_used_positions:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)

	# Calcola i limiti finali della mappa in coordinate di pixel
	var limit_left = min_x * tile_size.x
	var limit_top = min_y * tile_size.y
	var limit_right = (max_x + 1) * tile_size.x
	var limit_bottom = (max_y + 1) * tile_size.y

	print("📐 Limiti mappa combinati tra tutti i livelli:")
	print("Left: ", limit_left)
	print("Top: ", limit_top)
	print("Right: ", limit_right)
	print("Bottom: ", limit_bottom)
