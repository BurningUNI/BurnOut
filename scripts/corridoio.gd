#Corridoio.gd
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

var current_porta := "" # Memorizza quale porta il giocatore sta interagiendo

@onready var label := $InterazioneLabel # Etichetta per mostrare il messaggio di interazione
@onready var player := $Player # Nodo del giocatore
@onready var spawn_porta_casa := $SpawnPortaCasa # Punto di spawn vicino alla porta di casa
@onready var spawn_porta_classe := $SpawnPortaClasse # Punto di spawn vicino alla porta della classe

func _ready() -> void:
	# Registra la scena corrente nel StatsManager per il salvataggio
	StatsManager.current_scene_path = get_tree().current_scene.scene_file_path
	MusicController.play_music(MusicController.track_library["school"], "school")
	
	# Posiziona il giocatore in base all'ultima uscita dalla scena precedente
	match Global.last_exit:
		"portaCasa":
			player.global_position = spawn_porta_casa.global_position
		"uscito_da_classe":
			player.global_position = spawn_porta_classe.global_position
		_:
			pass # Posizione di default se non si proviene da una porta nota

func _process(_delta: float) -> void:
	# Controlla se il giocatore preme il tasto "interact" (SPAZIO) e se è vicino a una porta
	if Input.is_action_just_pressed("interact") and current_porta != "":
		match current_porta:
			"portaCasa":
				# Se è la porta di casa, cambia scena e salva
				Global.last_exit = "portaCasa"
				StatsManager.current_scene_path = "res://scenes/room.tscn"
				StatsManager.save_game()
				get_tree().change_scene_to_file("res://scenes/room.tscn")
			"portaClasse":
				# Se è la porta della classe, controlla prima se c'è una lezione attiva
				if is_lesson_active() != "none": # Modificato per controllare il nome della lezione
					Global.last_exit = "portaClasse"
					StatsManager.current_scene_path = "res://scenes/classe.tscn"
					StatsManager.save_game()
					get_tree().change_scene_to_file("res://scenes/classe.tscn")
				else:
					# Se non ci sono lezioni, non fare nulla (il messaggio è già visualizzato)
					pass

# Funzione che viene chiamata quando il giocatore entra nell'area della porta di casa
func _on_porta_casa_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = "portaCasa"
		label.text = "Premi SPAZIO per tornare a casa"
		label.visible = true

# Funzione che viene chiamata quando il giocatore esce dall'area della porta di casa
func _on_porta_casa_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = ""
		label.visible = false

# Funzione che viene chiamata quando il giocatore entra nell'area della porta della classe
func _on_porta_classe_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = "portaClasse"
		# Ottiene il nome della lezione attiva (o "none")
		var lezione_attiva = is_lesson_active()
		
		if lezione_attiva != "none":
			# Se c'è una lezione, mostra il messaggio con il nome della lezione
			label.text = "Premi SPAZIO per seguire " + lezione_attiva.capitalize()
		else:
			# Altrimenti, mostra il messaggio che non ci sono lezioni
			label.text = "Non ci sono lezioni in questo momento"
		label.visible = true

# Funzione che viene chiamata quando il giocatore esce dall'area della porta della classe
func _on_porta_classe_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		current_porta = ""
		label.visible = false

# ---- FUNZIONE MODIFICATA: Restituisce il nome della lezione attiva o "none" ----
func is_lesson_active() -> String:
	var current_ora = StatsManager.ora # Ora attuale dal StatsManager
	var current_minuti = StatsManager.minuti # Minuti attuali dal StatsManager
	# Indice del giorno della settimana (0=DOM, 1=LUN, ..., 6=SAB)
	var current_day_index = StatsManager.indice_giorno_settimana 

	# Le lezioni si tengono solo nei giorni feriali (LUN a VEN)
	if current_day_index < GIORNO_LUNEDI or current_day_index > GIORNO_VENERDI:
		return "none" # Non ci sono lezioni nel weekend

	# Converte l'ora e i minuti attuali in minuti totali dal mezzogiorno
	var total_minutes = current_ora * 60 + current_minuti

	# --- Controllo per la lezione di Analisi (8:30 - 11:00) ---
	var analisi_start_minutes = ORA_ANALISI_INIZIO * 60 + MINUTI_ANALISI_INIZIO
	var analisi_end_minutes = ORA_ANALISI_FINE * 60 + MINUTI_ANALISI_FINE
	# Se l'orario attuale è tra l'inizio e la fine della lezione di Analisi
	if total_minutes >= analisi_start_minutes and total_minutes < analisi_end_minutes:
		return "analisi" # Restituisce il nome della lezione

	# --- Controllo per la lezione di Programmazione (11:30 - 14:00) ---
	var programmazione_start_minutes = ORA_PROGRAMMAZIONE_INIZIO * 60 + MINUTI_PROGRAMMAZIONE_INIZIO
	var programmazione_end_minutes = ORA_PROGRAMMAZIONE_FINE * 60 + MINUTI_PROGRAMMAZIONE_FINE
	# Se l'orario attuale è tra l'inizio e la fine della lezione di Programmazione
	if total_minutes >= programmazione_start_minutes and total_minutes < programmazione_end_minutes:
		return "programmazione" # Restituisce il nome della lezione

	return "none" # Nessuna lezione attiva in questo momento
