extends Node2D

# ---- COSTANTI ORARI LEZIONI ----
# Lezione di Analisi: 8:30 - 11:00
const ORA_ANALISI_INIZIO = 8
const MINUTI_ANALISI_INIZIO = 30
const ORA_ANALISI_FINE = 11
const MINUTI_ANALISI_FINE = 0

# Lezione di Programmazione: 11:30 - 14:00
const ORA_PROGRAMMAZIONE_INIZIO = 11
const MINUTI_PROGRAMMAZIONE_INIZIO = 30
const ORA_PROGRAMMAZIONE_FINE = 14
const MINUTI_PROGRAMMAZIONE_FINE = 0

# Indici dei giorni della settimana per i giorni feriali (LUN a VEN)
const GIORNO_LUNEDI = 1
const GIORNO_VENERDI = 5

# ---- CONSTANTI MODIFICATORI ----
const PERDITA_SALUTE_MENTALE_LEZIONE = 5  # Minore rispetto allo studio alla scrivania (10)
const GUADAGNO_STUDIO_LEZIONE = 7         # Un buon guadagno per seguire la lezione

# ---- VARIABILI DI STATO ----
var near_door = false # Vero se il giocatore è vicino alla porta (area_porta)
var near_area_lezione = false # Vero se il giocatore è vicino all'area della lezione (areaLezione)

# ---- NODI ONREADY ----
@onready var label := $InterazioneLabel # Etichetta per mostrare il messaggio di interazione (vicino alla porta)
@onready var stats_manager = get_node("/root/StatsManager") # Manager globale delle statistiche
@onready var area_lezione: Area2D = $areaLezione # Il nodo Area2D che hai mostrato nell'immagine
@onready var lezione_label: Label = $areaLezione/Label # L'etichetta figlio di areaLezione per i messaggi specifici della lezione


func _ready() -> void:
	# Imposta il percorso della scena corrente per il salvataggio automatico
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	MusicController.play_music(MusicController.track_library["school"], "school")
	lezione_label.visible = false # Nascondi la label della lezione all'inizio


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		# Gestione interazione con la porta (per tornare nel corridoio)
		if near_door:
			# MODIFICA QUI: Indica chiaramente da quale porta sei uscito
			Global.last_exit = "uscito_da_classe" # Nuovo valore per identificare lo spawn corretto
			StatsManager.current_scene_path = "res://scenes/Corridoio.tscn"
			StatsManager.save_game()
			get_tree().change_scene_to_file("res://scenes/Corridoio.tscn")
		# Gestione interazione con l'area lezione
		elif near_area_lezione:
			var lezione_info = get_current_lesson_info() # Ottiene la lezione attiva (o "none")
			
			# MODIFICA QUI: Controlla se il tipo è un Dictionary (significa che una lezione è attiva)
			if typeof(lezione_info) == TYPE_DICTIONARY:
				segui_lezione(lezione_info)
			else:
				display_lezione_message("Non ci sono lezioni a cui partecipare ora.")


# ---- FUNZIONI DI INTERAZIONE CON LA PORTA (preesistenti) ----
func _on_area_porta_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_door = true
		label.text = "Premi SPAZIO per tornare nel corridoio"
		label.visible = true

func _on_area_porta_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_door = false
		label.visible = false

# ---- FUNZIONI DI INTERAZIONE CON AREA LEZIONE (MODIFICATE/AGGIUNTE) ----

func _on_area_lezione_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		near_area_lezione = true
		
		var lezione_info = get_current_lesson_info()
		
		# MODIFICA QUI: Controlla se il tipo è un Dictionary (significa che una lezione è attiva)
		if typeof(lezione_info) == TYPE_DICTIONARY:
			var lezione_nome = lezione_info["name"].capitalize()
			var fine_ora = lezione_info["end_hour"]
			var fine_minuti = lezione_info["end_minutes"]
			display_lezione_message("Premi [SPAZIO] per seguire %s (fino alle %02d:%02d)" % [lezione_nome, fine_ora, fine_minuti])
		else:
			display_lezione_message("Non ci sono lezioni a cui partecipare ora.")


func _on_area_lezione_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		near_area_lezione = false
		lezione_label.visible = false # Nascondi la label della lezione


# ---- LOGICA DELLA LEZIONE ----

# Restituisce un Dictionary con "name", "end_hour", "end_minutes" o la stringa "none"
func get_current_lesson_info() -> Variant:
	var current_ora = stats_manager.ora
	var current_minuti = stats_manager.minuti
	var current_day_index = stats_manager.indice_giorno_settimana 

	# Le lezioni si tengono solo nei giorni feriali (LUN a VEN)
	if current_day_index < GIORNO_LUNEDI or current_day_index > GIORNO_VENERDI:
		return "none"

	var total_minutes = current_ora * 60 + current_minuti

	# Analisi (8:30 - 11:00)
	var analisi_start_minutes = ORA_ANALISI_INIZIO * 60 + MINUTI_ANALISI_INIZIO
	var analisi_end_minutes = ORA_ANALISI_FINE * 60 + MINUTI_ANALISI_FINE
	if total_minutes >= analisi_start_minutes and total_minutes < analisi_end_minutes:
		return {"name": "analisi", "end_hour": ORA_ANALISI_FINE, "end_minutes": MINUTI_ANALISI_FINE}

	# Programmazione (11:30 - 14:00)
	var programmazione_start_minutes = ORA_PROGRAMMAZIONE_INIZIO * 60 + MINUTI_PROGRAMMAZIONE_INIZIO
	var programmazione_end_minutes = ORA_PROGRAMMAZIONE_FINE * 60 + MINUTI_PROGRAMMAZIONE_FINE
	if total_minutes >= programmazione_start_minutes and total_minutes < programmazione_end_minutes:
		return {"name": "programmazione", "end_hour": ORA_PROGRAMMAZIONE_FINE, "end_minutes": MINUTI_PROGRAMMAZIONE_FINE}

	return "none" # Nessuna lezione attiva

# Funzione per gestire l'effetto del seguire una lezione
func segui_lezione(lezione_info: Dictionary):
	var lezione_nome = lezione_info["name"]
	var fine_ora = lezione_info["end_hour"]
	var fine_minuti = lezione_info["end_minutes"]

	var current_total_minutes = stats_manager.ora * 60 + stats_manager.minuti
	var end_total_minutes = fine_ora * 60 + fine_minuti

	# Calcola quanti minuti devono avanzare
	var minuti_da_avanzare = end_total_minutes - current_total_minutes
	
	# Se per qualche motivo il tempo è già oltre la fine della lezione, non fare nulla
	if minuti_da_avanzare <= 0:
		display_lezione_message("Questa lezione è già terminata.")
		return

	# Avanza il tempo nel StatsManager
	stats_manager.avanza_minuti(minuti_da_avanzare)

	# Diminuisci la salute mentale
	stats_manager.diminuisci_salute_mentale(PERDITA_SALUTE_MENTALE_LEZIONE)

	# Aumenta lo stato di studio della materia
	stats_manager.aumenta_stato_studio(lezione_nome, GUADAGNO_STUDIO_LEZIONE)

	var message = "Hai seguito la lezione di %s fino alle %02d:%02d.\n" % [lezione_nome.capitalize(), fine_ora, fine_minuti]
	message += "Salute mentale -%d. Studio %s +%d." % [PERDITA_SALUTE_MENTALE_LEZIONE, lezione_nome.capitalize(), GUADAGNO_STUDIO_LEZIONE]
	display_lezione_message(message)

# ---- FUNZIONE AUSILIARIA PER I MESSAGGI DELLA LEZIONE ----
# Mostra un messaggio temporaneo sull'etichetta di interazione della lezione
func display_lezione_message(message: String, duration: float = 3.0) -> void:
	lezione_label.text = message
	lezione_label.visible = true
	lezione_label.modulate.a = 1.0 # Assicurati che sia completamente visibile all'inizio
	var tween = create_tween() # Crea un tween per far svanire l'etichetta
	tween.tween_interval(duration) # Attendi la durata specificata
	tween.tween_property(lezione_label, "modulate:a", 0.0, 1.0) # Svanisci l'opacità a 0
	tween.finished.connect(func(): # Quando il tween è finito
		lezione_label.visible = false # Nascondi l'etichetta
		lezione_label.modulate.a = 1.0 # Resetta l'opacità per il prossimo uso
	)
