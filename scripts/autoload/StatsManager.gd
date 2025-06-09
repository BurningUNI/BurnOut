#StatsManager.gd
extends Node

# --- Variabili di Stato del Gioco ---
var salute_mentale = 80
var soldi = 100 # Iniziali: 100 euro
var ora = 11
var minuti = 30
var giorno = 1

var is_first_boot = true
var nomi_giorni_settimana = ["DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB"]
var indice_giorno_settimana = 0

# Contatore per lo stipendio ogni 3 giorni
var giorni_dall_ultimo_stipendio = 0 # NUOVA VARIABILE

#ultima scena posizione
var current_scene_path = "res://scenes/room.tscn"  # valore di default

# VARIABILI PER LO STATO DI STUDIO
var statoAnalisi = 0
var statoProgrammazione = 0

# --- Segnali ---
signal salute_mentale_cambiata(nuova_salute)
signal soldi_cambiati(nuovi_soldi)
signal tempo_cambiato(nuova_ora, nuovi_minuti, nuovo_giorno_nome) # Questo segnale è cruciale
signal evento_casuale_triggerato(tipo_evento, messaggio, importo)
signal letto_pronto(letto_node_ref: Area2D)

# --- Timer ---
@onready var timer_tempo: Timer = Timer.new()
@onready var timer_eventi_settimanali: Timer = Timer.new() # Questo timer gestirà ora solo gli eventi casuali

const SAVE_GAME_PATH = "user://game_save.json"
var _letto_node: Area2D = null

func _ready():
	add_child(timer_tempo)
	add_child(timer_eventi_settimanali)

	if load_game():
		print("✅ StatsManager: Gioco caricato con successo!")
		print("📁 Scena da caricare al prossimo avvio:", current_scene_path)
	else:
		print("⚠️ StatsManager: Nessun salvataggio trovato o errore nel caricamento, inizio nuova partita.")
		print("📁 Scena di default (nessun salvataggio):", current_scene_path)
		# Se è una nuova partita, assicurati che i soldi siano 100 e il contatore stipendio a 0
		soldi = 100
		giorni_dall_ultimo_stipendio = 0


	# Timer Tempo (1 minuto gioco = 1 secondo reale)
	timer_tempo.wait_time = 1.0
	timer_tempo.timeout.connect(self._aggiorna_minuto_per_minuto)
	timer_tempo.start()

	# Timer Eventi Settimanali (ogni 7 giorni, ora solo per eventi casuali)
	# Lo imposteremo a 7 giorni * 24 ore * 60 minuti = 10080 minuti di gioco
	# Dato che 1 minuto di gioco = 1 secondo reale, è 10080 secondi reali
	timer_eventi_settimanali.wait_time = 10080.0 # 7 giorni di gioco (in secondi reali)
	timer_eventi_settimanali.timeout.connect(self._trigger_evento_casuale) # Collega direttamente all'evento casuale
	timer_eventi_settimanali.start()
	
	# Emetti i segnali iniziali per aggiornare subito l'UI
	emit_signal("salute_mentale_cambiata", salute_mentale)
	emit_signal("soldi_cambiati", soldi)
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

# --- Stato ---
func aumenta_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale + quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("StatsManager: Salute mentale aumentata a: ", salute_mentale)

func diminuisci_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale - quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("StatsManager: Salute mentale diminuita a: ", salute_mentale)

func aggiungi_soldi(quantita: int):
	soldi += quantita
	emit_signal("soldi_cambiati", soldi)
	print("StatsManager: Soldi aggiunti. Totale: ", soldi)

func sottrai_soldi(quantita: int):
	if soldi >= quantita:
		soldi -= quantita
		emit_signal("soldi_cambiati", soldi)
		print("StatsManager: Soldi sottratti. Totale: ", soldi)
		return true
	else:
		print("StatsManager: Soldi insufficienti per sottrarre ", quantita, ". Totale: ", soldi)
		return false

# --- Gestione del Tempo ---

# Questa funzione viene chiamata ogni tick del timer (ogni secondo reale)
func _aggiorna_minuto_per_minuto():
	minuti += 1
	_check_and_update_time()

# AVANZA IL TEMPO DI UN CERTO NUMERO DI MINUTI
func avanza_minuti(quantita_minuti: int):
	minuti += quantita_minuti
	_check_and_update_time()

# AVANZA IL TEMPO DI UN CERTO NUMERO DI ORE (come per "studia" o "dormi")
func avanza_ore(quantita_ore: int):
	ora += quantita_ore
	_check_and_update_time()

# FUNZIONE CENTRALE PER CONTROLLARE E AGGIORNARE MINUTI/ORE/GIORNI
# Questa funzione gestisce i "rollover" (es. 60 minuti diventano 1 ora)
func _check_and_update_time():
	var updated_day = false # Flag per vedere se il giorno è cambiato

	# Gestisce il rollover dei minuti in ore
	while minuti >= 60:
		minuti -= 60
		ora += 1
	
	# Gestisce il rollover delle ore in giorni
	while ora >= 24:
		ora -= 24
		giorno += 1
		indice_giorno_settimana = (indice_giorno_settimana + 1) % 7
		giorni_dall_ultimo_stipendio += 1 # Incrementa il contatore dei giorni
		_controlla_e_assegna_stipendio() # Chiamata alla nuova funzione di controllo stipendio
		updated_day = true

	# Emetti il segnale tempo_cambiato SOLO UNA VOLTA dopo tutti gli aggiornamenti
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

# NUOVA FUNZIONE PER GESTIRE LO STIPENDIO OGNI X GIORNI
func _controlla_e_assegna_stipendio():
	const GIORNI_PER_STIPENDIO = 3
	const AMMONTARE_STIPENDIO = 25

	if giorni_dall_ultimo_stipendio >= GIORNI_PER_STIPENDIO:
		aggiungi_soldi(AMMONTARE_STIPENDIO)
		print("StatsManager: Stipendio di ", AMMONTARE_STIPENDIO, " euro ricevuto dopo ", giorni_dall_ultimo_stipendio, " giorni.")
		giorni_dall_ultimo_stipendio = 0 # Resetta il contatore


# NUOVA FUNZIONE PER AUMENTARE LO STATO DI STUDIO
func aumenta_stato_studio(materia: String, quantita: int):
	match materia:
		"analisi":
			statoAnalisi = clampi(statoAnalisi + quantita, 0, 100)
			print("StatsManager: Stato Analisi aumentato a: ", statoAnalisi)
		"programmazione":
			statoProgrammazione = clampi(statoProgrammazione + quantita, 0, 100)
			print("StatsManager: Stato Programmazione aumentato a: ", statoProgrammazione)

# --- Eventi Settimanali (Solo eventi casuali, lo stipendio è gestito a parte) ---
# La funzione _aggiorna_soldi_settimanali() è stata rimossa o svuotata perché lo stipendio
# ora è gestito da _controlla_e_assegna_stipendio()
func _gestisci_eventi_settimanali(): # Questo segnale ora è collegato solo a _trigger_evento_casuale
	pass # Non c'è più bisogno di logica qui, è stata spostata/adattata

func _trigger_evento_casuale():
	print("StatsManager: Trigger Evento Casuale!") # Aggiunto per debug
	var eventi = [
		{"nome": "Multa per divieto di sosta", "costo": randi_range(50, 150), "messaggio": "Hai ricevuto una multa inaspettata!"},
		{"nome": "Spesa medica", "costo": randi_range(100, 300), "messaggio": "Una visita dal medico urgente... costa cara."},
		{"nome": "Ripara guasto in casa", "costo": randi_range(75, 250), "messaggio": "Un tubo rotto? È ora di chiamare l'idraulico!"},
		{"nome": "Offerta speciale", "costo": -randi_range(20, 80), "messaggio": "Offerta speciale! Hai risparmiato un po' di soldi!"}
	]
	var evento_scelto = eventi[randi_range(0, eventi.size() - 1)]
	var tipo = evento_scelto.nome
	var importo = evento_scelto.costo
	var messaggio = evento_scelto.messaggio

	if importo > 0: # È un costo
		if sottrai_soldi(importo):
			emit_signal("evento_casuale_triggerato", tipo, messaggio, importo)
			print("StatsManager: Evento casuale: ", tipo, " - Costo: ", importo)
		else:
			print("StatsManager: Evento casuale fallito per soldi insufficienti: ", tipo)
	else: # È un guadagno
		aggiungi_soldi(abs(importo))
		emit_signal("evento_casuale_triggerato", tipo, messaggio, abs(importo))
		print("StatsManager: Evento casuale: ", tipo, " - Guadagno: ", abs(importo))

# --- Funzione per la rigenerazione della salute mentale ---
func _on_mental_health_timer_timeout():
	var restore_amount = ceil(salute_mentale * 0.10) # Calcola il 10% della salute mentale attuale, arrotondato per eccesso
	if restore_amount == 0 and salute_mentale < 100: # Assicurati che venga ripristinato almeno 1 punto se non è al massimo
		restore_amount = 1
	aumenta_salute_mentale(restore_amount)
	print("StatsManager: Salute mentale rigenerata di ", restore_amount, " (10% ogni 10 secondi).")

# --- Funzione Helper per il "clamp" (limita un valore tra un minimo e un massimo) ---
func clampi(value: int, min_val: int, max_val: int) -> int:
	return maxi(min_val, mini(value, max_val))

# --- Salvataggio ---
func save_game() -> Error:
	var save_dict = {
		"salute_mentale": salute_mentale,
		"soldi": soldi,
		"ora": ora,
		"minuti": minuti,
		"giorno": giorno,
		"indice_giorno_settimana": indice_giorno_settimana,
		"giorni_dall_ultimo_stipendio": giorni_dall_ultimo_stipendio, # SALVA LA NUOVA VARIABILE
		"is_first_boot": false,
		"current_scene_path": current_scene_path,
		"statoAnalisi": statoAnalisi,
		"statoProgrammazione": statoProgrammazione
	}

	var file = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	if file == null:
		print("StatsManager: Errore nell'apertura del file per scrittura: ", FileAccess.get_open_error())
		return ERR_CANT_OPEN

	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	print("StatsManager: Gioco salvato con successo in: ", SAVE_GAME_PATH)
	print("StatsManager: Scena salvata:", current_scene_path)
	return OK

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		print("StatsManager: Nessun file di salvataggio trovato.")
		is_first_boot = true
		return false

	var file = FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	if file == null:
		print("StatsManager: Errore apertura file salvataggio.")
		is_first_boot = true
		return false

	var content = file.get_as_text()
	file.close()
	var json_parsed = JSON.parse_string(content)
	if json_parsed == null:
		print("StatsManager: Errore nel parsing del salvataggio.")
		is_first_boot = true
		return false

	salute_mentale = int(json_parsed.get("salute_mentale", 100))
	soldi = int(json_parsed.get("soldi", 100)) # Default per i soldi impostato a 100
	ora = int(json_parsed.get("ora", 11))
	minuti = int(json_parsed.get("minuti", 30))
	giorno = int(json_parsed.get("giorno", 1))
	indice_giorno_settimana = int(json_parsed.get("indice_giorno_settimana", 0))
	giorni_dall_ultimo_stipendio = int(json_parsed.get("giorni_dall_ultimo_stipendio", 0)) # CARICA LA NUOVA VARIABILE
	is_first_boot = bool(json_parsed.get("is_first_boot", true))
	current_scene_path = json_parsed.get("current_scene_path", "res://scenes/room.tscn")
	# CARICA NUOVE VARIABILI STUDIO
	statoAnalisi = int(json_parsed.get("statoAnalisi", 0))
	statoProgrammazione = int(json_parsed.get("statoProgrammazione", 0))

	print("StatsManager: Scena caricata:", current_scene_path)
	return true

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		print("StatsManager: Salvataggio automatico alla chiusura.")

# --- Registrazione letto ---
func register_bed(bed_node: Area2D):
	_letto_node = bed_node
	emit_signal("letto_pronto", bed_node)
	print("StatsManager: Letto registrato.")
