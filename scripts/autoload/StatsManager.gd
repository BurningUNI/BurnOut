# StatsManager.gd
extends Node

# --- Variabili di Stato del Gioco ---
var salute_mentale = 80
var soldi = 500
var ora = 11
var minuti = 30
var giorno = 1

var is_first_boot = true
var nomi_giorni_settimana = ["DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB"]
var indice_giorno_settimana = 0

#ultima scena posizione
var current_scene_path = "res://scenes/room.tscn"  # valore di default
# --- Segnali ---
signal salute_mentale_cambiata(nuova_salute)
signal soldi_cambiati(nuovi_soldi)
signal tempo_cambiato(nuova_ora, nuovi_minuti, nuovo_giorno_nome)
signal evento_casuale_triggerato(tipo_evento, messaggio, importo)
signal letto_pronto(letto_node_ref: Area2D)

# --- Timer ---
@onready var timer_tempo: Timer = Timer.new()
@onready var timer_eventi_settimanali: Timer = Timer.new()

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

	# Timer Tempo (1 minuto gioco = 1 secondo reale)
	timer_tempo.wait_time = 1.0
	timer_tempo.timeout.connect(self._aggiorna_tempo)
	timer_tempo.start()

	# Timer Eventi Settimanali (ogni 10080 secondi)
	timer_eventi_settimanali.wait_time = 10080.0
	timer_eventi_settimanali.timeout.connect(self._gestisci_eventi_settimanali)
	timer_eventi_settimanali.start()

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

# --- Tempo ---
func _aggiorna_tempo():
	minuti += 1
	if minuti >= 60:
		minuti = 0
		ora += 1
		if ora >= 24:
			ora = 0
			giorno += 1
			indice_giorno_settimana = (indice_giorno_settimana + 1) % 7
			_aggiorna_soldi_settimanali()
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

# --- Eventi Settimanali ---
func _aggiorna_soldi_settimanali():
	pass

func _gestisci_eventi_settimanali():
	print("StatsManager: Aggiornamento Settimanale!")
	var stipendio_settimanale = 200
	aggiungi_soldi(stipendio_settimanale)
	print("StatsManager: Stipendio settimanale ricevuto: ", stipendio_settimanale)

	if randi_range(0, 99) < 40:
		_trigger_evento_casuale()

func _trigger_evento_casuale():
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

	if importo > 0:
		if sottrai_soldi(importo):
			emit_signal("evento_casuale_triggerato", tipo, messaggio, importo)
			print("StatsManager: Evento casuale: ", tipo, " - Costo: ", importo)
		else:
			print("StatsManager: Evento casuale fallito per soldi insufficienti: ", tipo)
	else:
		aggiungi_soldi(abs(importo))
		emit_signal("evento_casuale_triggerato", tipo, messaggio, abs(importo))
		print("StatsManager: Evento casuale: ", tipo, " - Guadagno: ", abs(importo))

# --- Helper ---
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
		"is_first_boot": false,
		"current_scene_path": current_scene_path  # 👈 nuova riga
	}

	var file = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	if file == null:
		print("StatsManager: Errore nell'apertura del file per scrittura: ", FileAccess.get_open_error())
		return ERR_CANT_OPEN

	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	print("StatsManager: Gioco salvato con successo in: ", SAVE_GAME_PATH)
	print("StatsManager: Scena salvata:", current_scene_path)  # debug
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
	soldi = int(json_parsed.get("soldi", 500))
	ora = int(json_parsed.get("ora", 11))
	minuti = int(json_parsed.get("minuti", 30))
	giorno = int(json_parsed.get("giorno", 1))
	indice_giorno_settimana = int(json_parsed.get("indice_giorno_settimana", 0))
	is_first_boot = bool(json_parsed.get("is_first_boot", true))
	current_scene_path = json_parsed.get("current_scene_path", "res://scenes/room.tscn")  # 👈 nuova riga

	print("StatsManager: Scena caricata:", current_scene_path)  # debug
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
