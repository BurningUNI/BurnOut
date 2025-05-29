# GameState.gd
extends Node

# --- Variabili di Stato del Gioco ---
var salute_mentale = 100
var soldi = 500
var ora = 11
var minuti = 30
var giorno = 1 # Numero del giorno corrente (1, 2, 3...)

# Nuovo: Array per i nomi dei giorni della settimana
var nomi_giorni_settimana = ["DOM", "LUN", "MAR", "MER", "GIO", "VEN", "SAB"]
var indice_giorno_settimana = 0 # 0 = Domenica, 1 = Lunedì, ecc. (corrisponde all'array)

# --- Segnali Custom per Aggiornare l'UI ---
signal salute_mentale_cambiata(nuova_salute)
signal soldi_cambiati(nuovi_soldi)
signal tempo_cambiato(nuova_ora, nuovi_minuti, nuovo_giorno_nome)
signal evento_casuale_triggerato(tipo_evento, messaggio, importo)

# --- Nuovo Segnale per il Letto (per la comunicazione con la HUD) ---
signal letto_pronto(letto_node_ref: Area2D)

# --- Timer ---
@onready var timer_tempo: Timer = Timer.new()
@onready var timer_eventi_settimanali: Timer = Timer.new()

# Nuovo: Percorso del file di salvataggio
const SAVE_PATH = "user://game_save.json"

# Riferimento al nodo letto (opzionale, ma utile se altri script ne avessero bisogno)
var _letto_node: Area2D = null

func _ready():
	add_child(timer_tempo)
	add_child(timer_eventi_settimanali)

	# Tenta di caricare lo stato salvato all'avvio
	if load_game():
		print("Gioco caricato con successo!")
	else:
		print("Nessun salvataggio trovato o errore nel caricamento, inizio nuova partita.")
		# Se non c'è un salvataggio, inizializza le variabili ai valori predefiniti
		# (che sono già quelli che hai dichiarato all'inizio dello script)

	# Configurazione Timer Tempo (1 minuto reale = 1 ora di gioco)
	timer_tempo.wait_time = 1.0 # Ogni 1 secondo reale, il tempo di gioco avanza di 1 minuto
	timer_tempo.timeout.connect(self._aggiorna_tempo)
	timer_tempo.start()

	# Configurazione Timer Eventi Casuali (Settimanali)
	# Una settimana di gioco = 7 giorni * 24 ore/giorno * 60 minuti/ora = 10080 minuti di gioco.
	# Visto che 1 minuto di gioco = 1 secondo reale, allora: 10080 minuti di gioco * 1 secondo/minuto = 10080 secondi reali.
	timer_eventi_settimanali.wait_time = 10080.0
	timer_eventi_settimanali.timeout.connect(self._gestisci_eventi_settimanali)
	timer_eventi_settimanali.start()

	# Emetti i segnali iniziali per popolare la UI all'avvio della scena
	emit_signal("salute_mentale_cambiata", salute_mentale)
	emit_signal("soldi_cambiati", soldi)
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

# --- Funzioni per Modificare lo Stato del Gioco ---

func aumenta_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale + quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("Salute mentale aumentata a: ", salute_mentale)

func diminuisci_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale - quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("Salute mentale diminuita a: ", salute_mentale)

func aggiungi_soldi(quantita: int):
	soldi += quantita
	emit_signal("soldi_cambiati", soldi)
	print("Soldi aggiunti. Totale: ", soldi)

func sottrai_soldi(quantita: int):
	if soldi >= quantita:
		soldi -= quantita
		emit_signal("soldi_cambiati", soldi)
		print("Soldi sottratti. Totale: ", soldi)
		return true
	else:
		print("Soldi insufficienti per sottrarre ", quantita, ". Totale: ", soldi)
		return false

# --- Gestione del Tempo ---

func _aggiorna_tempo():
	minuti += 1

	if minuti >= 60:
		minuti = 0
		ora += 1

		if ora >= 24:
			ora = 0
			giorno += 1
			indice_giorno_settimana = (indice_giorno_settimana + 1) % 7 # Incrementa l'indice del giorno della settimana
			_aggiorna_soldi_settimanali() # Aggiorna i soldi ogni nuovo giorno (puoi modificarlo a fine settimana)

	# Emetti il segnale tempo_cambiato con i nuovi valori per aggiornare la UI
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])
	#print("Ora di gioco: %02d:%02d, Giorno: %d" % [ora, minuti, giorno])

# --- Gestione Eventi Casuali e Soldi Settimanali ---

func _aggiorna_soldi_settimanali():
	pass # Puoi implementare la logica per aggiornare i soldi qui, ad esempio ogni fine settimana

func _gestisci_eventi_settimanali():
	print("Aggiornamento Settimanale!")
	var stipendio_settimanale = 200
	aggiungi_soldi(stipendio_settimanale)
	print("Stipendio settimanale ricevuto: ", stipendio_settimanale)

	if randi_range(0, 99) < 40: # 40% di possibilità di un evento casuale
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

	if importo > 0: # Se è un costo (importo positivo)
		if sottrai_soldi(importo): # Prova a sottrarre i soldi
			emit_signal("evento_casuale_triggerato", tipo, messaggio, importo)
			print("Evento casuale: ", tipo, " - Costo: ", importo, " Soldi rimanenti: ", soldi)
		else:
			print("Evento casuale fallito per soldi insufficienti: ", tipo) # Non hai abbastanza soldi per l'evento
	else: # Se è un guadagno (importo negativo)
		aggiungi_soldi(abs(importo)) # Aggiungi il valore assoluto
		emit_signal("evento_casuale_triggerato", tipo, messaggio, abs(importo))
		print("Evento casuale: ", tipo, " - Guadagno: ", abs(importo), " Soldi totali: ", soldi)

# Funzione helper per 'clamping' (limitare un valore tra un minimo e un massimo)
func clampi(value: int, min_val: int, max_val: int) -> int:
	return maxi(min_val, mini(value, max_val))


# --- Funzioni di Salvataggio e Caricamento ---

func save_game() -> Error:
	var save_dict = {
		"salute_mentale": salute_mentale,
		"soldi": soldi,
		"ora": ora,
		"minuti": minuti,
		"giorno": giorno,
		"indice_giorno_settimana": indice_giorno_settimana
		# Aggiungi qui tutte le altre variabili che vuoi salvare
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("Errore nell'apertura del file per scrittura: ", FileAccess.get_open_error())
		return ERR_CANT_OPEN

	var json_string = JSON.stringify(save_dict, "\t") # Il "\t" aggiunge indentazione per leggibilità
	file.store_string(json_string)
	file.close()
	print("Gioco salvato con successo in: ", SAVE_PATH)
	return OK

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Nessun file di salvataggio trovato in: ", SAVE_PATH)
		return false # Nessun file da caricare

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("Errore nell'apertura del file per lettura: ", FileAccess.get_open_error())
		return false

	var content = file.get_as_text()
	file.close()

	var json_parsed = JSON.parse_string(content)
	if json_parsed == null:
		print("Errore nel parsing JSON del file di salvataggio.")
		return false

	# Assegna i valori caricati alle variabili di stato
	salute_mentale = int(json_parsed.get("salute_mentale", 100)) # Il secondo argomento è il default se la chiave non esiste
	soldi = int(json_parsed.get("soldi", 500))
	ora = int(json_parsed.get("ora", 11))
	minuti = int(json_parsed.get("minuti", 30))
	giorno = int(json_parsed.get("giorno", 1))
	indice_giorno_settimana = int(json_parsed.get("indice_giorno_settimana", 0))

	# Aggiungi qui il caricamento di tutte le altre variabili

	return true

func _notification(what):
	# NOTIFICATION_WM_CLOSE_REQUEST è inviato quando la finestra del gioco sta per chiudersi
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		print("Salvataggio automatico alla chiusura.")

# --- Nuova funzione per permettere al letto di registrarsi al GameState ---
func register_bed(bed_node: Area2D):
	_letto_node = bed_node
	emit_signal("letto_pronto", bed_node) # Emette il segnale per informare chi è interessato (come la HUD)
	print("GameState: Letto registrato.")
