#StatsManager
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
var giorni_dall_ultimo_stipendio = 0

# Ultima scena posizione (per salvare e caricare la scena corretta)
var current_scene_path = "res://scenes/room.tscn" # Valore di default

# VARIABILI PER LO STATO DI STUDIO
var statoAnalisi = 0
var statoProgrammazione = 0

# --- Segnali ---
# Emessi quando i valori corrispondenti cambiano, per aggiornare l'UI o altre logiche.
signal salute_mentale_cambiata(nuova_salute)
signal soldi_cambiati(nuovi_soldi)
signal tempo_cambiato(nuova_ora, nuovi_minuti, nuovo_giorno_nome)
signal evento_casuale_triggerato(tipo_evento, messaggio, importo)
signal letto_pronto(letto_node_ref: Area2D)

# NUOVO SEGNALE: Emesso quando la salute mentale raggiunge 0, per attivare il Game Over.
signal game_over_salute_mentale()

# --- Nodi Figli (@onready) ---
@onready var timer_tempo: Timer = Timer.new()
@onready var timer_eventi_settimanali: Timer = Timer.new()

# --- Costanti ---
const SAVE_GAME_PATH = "user://game_save.json" # Percorso del file di salvataggio del gioco

# --- Variabili Interne ---
var _letto_node: Area2D = null # Riferimento al nodo del letto, se registrato

# --- Funzioni Base di Godot ---

func _ready():
	# Aggiunge i timer come figli del nodo per gestirli automaticamente
	add_child(timer_tempo)
	add_child(timer_eventi_settimanali)

	var loaded_successfully = load_game()
	if loaded_successfully:
		print("StatsManager: Gioco caricato con successo!")
		print("Scena da caricare al prossimo avvio:", current_scene_path)
	else:
		print("StatsManager: Nessun salvataggio trovato o errore nel caricamento, inizio nuova partita.")
		print("Scena di default (nessun salvataggio):", current_scene_path)
		# Assicurati che i soldi e il contatore stipendio siano a valori iniziali per una nuova partita
		soldi = 100
		giorni_dall_ultimo_stipendio = 0
		# Imposta l'ora di default per un nuovo gioco, se non c'è salvataggio
		ora = 7 # Esempio: inizia alle 7 del mattino
		minuti = 0
		giorno = 1
		indice_giorno_settimana = 1 # Esempio: Lunedì (indice 1)

	# Configura e avvia il timer del tempo (1 minuto di gioco = 1 secondo reale)
	timer_tempo.wait_time = 1.0
	timer_tempo.timeout.connect(self._aggiorna_minuto_per_minuto)
	timer_tempo.start()

	# Configura e avvia il timer per gli eventi settimanali casuali
	# (7 giorni * 24 ore * 60 minuti = 10080 minuti di gioco, che corrispondono a 10080 secondi reali)
	timer_eventi_settimanali.wait_time = 10080.0
	timer_eventi_settimanali.timeout.connect(self._trigger_evento_casuale)
	timer_eventi_settimanali.start()
	
	# Emette i segnali iniziali PER AGGIORNARE L'UI con i valori caricati o di default
	# Questo blocco DEVE essere dopo il caricamento del gioco.
	emit_signal("salute_mentale_cambiata", salute_mentale)
	emit_signal("soldi_cambiati", soldi)
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])


# Chiamata quando l'applicazione sta per chiudersi (es. clic sulla X della finestra)
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game() # Salva automaticamente il gioco
		print("StatsManager: Salvataggio automatico alla chiusura.")

# --- Gestione delle Statistiche del Giocatore ---

## Salute Mentale
func aumenta_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale + quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("StatsManager: Salute mentale aumentata a: ", salute_mentale)

func diminuisci_salute_mentale(quantita: int):
	salute_mentale = clampi(salute_mentale - quantita, 0, 100)
	emit_signal("salute_mentale_cambiata", salute_mentale)
	print("StatsManager: Salute mentale diminuita a: ", salute_mentale)
	# Controlla se la salute mentale è arrivata a 0 o meno
	if salute_mentale <= 0:
		emit_signal("game_over_salute_mentale") # Emette il segnale di Game Over
		print("StatsManager: GAME OVER - Salute mentale esaurita!")

## Soldi
func aggiungi_soldi(quantita: int):
	soldi += quantita
	emit_signal("soldi_cambiati", soldi)
	print("StatsManager: Soldi aggiunti. Totale: ", soldi)

func sottrai_soldi(quantita: int):
	if soldi >= quantita:
		soldi -= quantita
		emit_signal("soldi_cambiati", soldi)
		print("StatsManager: Soldi sottratti. Totale: ", soldi)
		return true # Operazione riuscita
	else:
		print("StatsManager: Soldi insufficienti per sottrarre ", quantita, ". Totale: ", soldi)
		return false # Soldi insufficienti

## Stato di Studio
func aumenta_stato_studio(materia: String, quantita: int):
	match materia:
		"analisi":
			statoAnalisi = clampi(statoAnalisi + quantita, 0, 100)
			print("StatsManager: Stato Analisi aumentato a: ", statoAnalisi)
		"programmazione":
			statoProgrammazione = clampi(statoProgrammazione + quantita, 0, 100)
			print("StatsManager: Stato Programmazione aumentato a: ", statoProgrammazione)

# --- Gestione del Tempo ---

# Funzione chiamata ogni secondo reale per avanzare di un minuto di gioco
func _aggiorna_minuto_per_minuto():
	minuti += 1
	_check_and_update_time()

# Funzione per avanzare il tempo di un certo numero di minuti
func avanza_minuti(quantita_minuti: int):
	minuti += quantita_minuti
	_check_and_update_time()

# Funzione per avanzare il tempo di un certo numero di ore (usata per azioni lunghe come dormire o studiare)
func avanza_ore(quantita_ore: int):
	ora += quantita_ore
	_check_and_update_time()

# Funzione centrale per controllare e aggiornare minuti, ore e giorni (gestisce i "rollover")
func _check_and_update_time():
	# Gestisce il rollover dei minuti in ore
	while minuti >= 60:
		minuti -= 60
		ora += 1
	
	# Gestisce il rollover delle ore in giorni
	while ora >= 24:
		ora -= 24
		giorno += 1
		indice_giorno_settimana = (indice_giorno_settimana + 1) % 7 # Avanza il giorno della settimana (DOM, LUN, ...)
		giorni_dall_ultimo_stipendio += 1 # Incrementa il contatore per lo stipendio
		_controlla_e_assegna_stipendio() # Controlla e assegna lo stipendio se dovuto

	# Emette il segnale tempo_cambiato SOLO UNA VOLTA dopo tutti gli aggiornamenti
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

# Funzione per gestire l'assegnazione dello stipendio ogni X giorni
func _controlla_e_assegna_stipendio():
	const GIORNI_PER_STIPENDIO = 4 # Modificato a 4 giorni come richiesto
	const AMMONTARE_STIPENDIO = 25

	if giorni_dall_ultimo_stipendio >= GIORNI_PER_STIPENDIO:
		aggiungi_soldi(AMMONTARE_STIPENDIO)
		print("StatsManager: Stipendio di ", AMMONTARE_STIPENDIO, " euro ricevuto dopo ", giorni_dall_ultimo_stipendio, " giorni.")
		giorni_dall_ultimo_stipendio = 0 # Resetta il contatore dello stipendio

# --- Eventi Casuali ---

# Funzione per la rigenerazione della salute mentale (attualmente non collegata a un timer,
# ma puoi collegarla a un timer in una scena specifica se necessario)
func _on_mental_health_timer_timeout():
	var restore_amount = ceil(salute_mentale * 0.10) # Calcola il 10% della salute mentale attuale
	if restore_amount == 0 and salute_mentale < 100: # Assicurati che venga ripristinato almeno 1 punto se non al massimo
		restore_amount = 1
	aumenta_salute_mentale(restore_amount)
	print("StatsManager: Salute mentale rigenerata di ", restore_amount, " (10% ogni 10 secondi).")

# Funzione per attivare un evento casuale (collegata al timer_eventi_settimanali)
func _trigger_evento_casuale():
	print("StatsManager: Trigger Evento Casuale!")
	var eventi = [
		{"nome": "Multa per divieto di sosta", "costo": randi_range(20, 80), "messaggio": "Hai ricevuto una multa inaspettata!"},
		{"nome": "Spesa medica", "costo": randi_range(30, 100), "messaggio": "Una visita dal medico urgente... costa cara."},
		{"nome": "Ripara guasto in casa", "costo": randi_range(25, 90), "messaggio": "Un tubo rotto? È ora di chiamare l'idraulico!"},
		{"nome": "Offerta speciale", "costo": -randi_range(30, 100), "messaggio": "Offerta speciale! Hai risparmiato un po' di soldi!"}
	]
	var evento_scelto = eventi[randi_range(0, eventi.size() - 1)]
	var tipo = evento_scelto.nome
	var importo = evento_scelto.costo
	var messaggio = evento_scelto.messaggio

	if importo > 0: # È un costo (denaro sottratto)
		if sottrai_soldi(importo): # La funzione sottrai_soldi() ora gestisce il controllo dei fondi
			emit_signal("evento_casuale_triggerato", tipo, messaggio, importo)
			print("StatsManager: Evento casuale: ", tipo, " - Costo: ", importo)
		else:
			# L'evento non avviene per soldi insufficienti
			print("StatsManager: Evento casuale fallito per soldi insufficienti: ", tipo, " (necessari: ", importo, ", disponibili: ", soldi, ")")
	else: # È un guadagno (denaro aggiunto)
		aggiungi_soldi(abs(importo)) # abs() per trasformare il costo negativo in un guadagno positivo
		emit_signal("evento_casuale_triggerato", tipo, messaggio, abs(importo))
		print("StatsManager: Evento casuale: ", tipo, " - Guadagno: ", abs(importo))

# --- Funzioni Helper ---

# Funzione per limitare un valore tra un minimo e un massimo (clamp)
func clampi(value: int, min_val: int, max_val: int) -> int:
	return maxi(min_val, mini(value, max_val))

# --- Gestione del Salvataggio e Caricamento ---

func save_game() -> Error:
	var save_dict = {
		"salute_mentale": salute_mentale,
		"soldi": soldi,
		"ora": ora,
		"minuti": minuti,
		"giorno": giorno,
		"indice_giorno_settimana": indice_giorno_settimana,
		"giorni_dall_ultimo_stipendio": giorni_dall_ultimo_stipendio, # SALVA LA NUOVA VARIABILE
		"is_first_boot": false, # Imposta a false dopo il primo salvataggio
		"current_scene_path": current_scene_path,
		"statoAnalisi": statoAnalisi,
		"statoProgrammazione": statoProgrammazione
	}

	var file = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	if file == null:
		print("StatsManager: Errore nell'apertura del file per scrittura: ", FileAccess.get_open_error())
		return ERR_CANT_OPEN

	# Converte il dizionario in una stringa JSON formattata
	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()
	print("StatsManager: Gioco salvato con successo in: ", SAVE_GAME_PATH)
	print("StatsManager: Scena salvata:", current_scene_path)
	return OK

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		print("StatsManager: Nessun file di salvataggio trovato.")
		is_first_boot = true # Se non c'è salvataggio, è il primo avvio
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

	# Carica i dati dal JSON, usando valori di default se la chiave non esiste
	salute_mentale = int(json_parsed.get("salute_mentale", 100))
	soldi = int(json_parsed.get("soldi", 100))
	ora = int(json_parsed.get("ora", 11))
	minuti = int(json_parsed.get("minuti", 30))
	giorno = int(json_parsed.get("giorno", 1))
	indice_giorno_settimana = int(json_parsed.get("indice_giorno_settimana", 0))
	giorni_dall_ultimo_stipendio = int(json_parsed.get("giorni_dall_ultimo_stipendio", 0))
	is_first_boot = bool(json_parsed.get("is_first_boot", true))
	current_scene_path = json_parsed.get("current_scene_path", "res://scenes/room.tscn")
	statoAnalisi = int(json_parsed.get("statoAnalisi", 0))
	statoProgrammazione = int(json_parsed.get("statoProgrammazione", 0))

	print("StatsManager: Scena caricata:", current_scene_path)
	return true

# --- Altre Funzioni Utili ---
func imposta_orario(nuova_ora: int, nuovi_minuti: int):
	ora = nuova_ora
	minuti = nuovi_minuti
	# Emetti il segnale 'tempo_cambiato' per aggiornare l'HUD e qualsiasi altro nodo in ascolto
	# Si assume che 'nomi_giorni_settimana' e 'indice_giorno_settimana' siano già gestiti altrove per il giorno corrente
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])
	print("StatsManager: Orario impostato manualmente a ", "%02d:%02d" % [ora, minuti])
# Registra il nodo del letto per interazioni future
func register_bed(bed_node: Area2D):
	_letto_node = bed_node
	emit_signal("letto_pronto", bed_node)
	print("StatsManager: Letto registrato.")

# Funzione per resettare tutte le statistiche di gioco ai valori iniziali
func resetta_statistiche():
	print("StatsManager: Reset dei dati in corso...")

	# Reimposta le variabili principali
	salute_mentale = 100
	soldi = 100
	ora = 11
	minuti = 30
	giorno = 1
	indice_giorno_settimana = 0
	giorni_dall_ultimo_stipendio = 0
	is_first_boot = true
	current_scene_path = "res://scenes/room.tscn"

	# Reimposta gli stati di studio
	statoAnalisi = 0
	statoProgrammazione = 0

	# Salva i nuovi dati (resettati)
	save_game()

	# Emette i segnali per aggiornare subito l'interfaccia utente dopo il reset
	emit_signal("salute_mentale_cambiata", salute_mentale)
	emit_signal("soldi_cambiati", soldi)
	emit_signal("tempo_cambiato", ora, minuti, nomi_giorni_settimana[indice_giorno_settimana])

	print("StatsManager: Reset completato.")
