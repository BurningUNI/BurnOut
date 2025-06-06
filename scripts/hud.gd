# HUD.gd
extends CanvasLayer # Il nodo radice della scena HUD.tscn DEVE essere di tipo CanvasLayer

@onready var statistiche_sfondo: Panel = $StatisticheSfondo

# Riferimenti per la Salute Mentale
@onready var salute_mentale_bar: TextureProgressBar = $StatisticheSfondo/SaluteMentaleBar

# Riferimenti per i Soldi
@onready var soldi_quantita_label: Label = $StatisticheSfondo/SoldiIcona/QuantitaSoldi # Il testo dei soldi (figlio dell'icona)

# Riferimento per l'Orologio e il Giorno della settimana
@onready var orologio_label: Label = $StatisticheSfondo/OrologioLabel

# Nuovo riferimento per la label di notifica dei messaggi temporanei (per il letto, eventi casuali, ecc.)
@onready var notifica_messaggio_label: Label = $NotificaMessaggioLabel

# Riferimento al nodo Autoload StatsManager
@onready var stats_manager: Node = get_node("/root/StatsManager")


func _ready():

	stats_manager.salute_mentale_cambiata.connect(self._on_salute_mentale_cambiata)
	stats_manager.soldi_cambiati.connect(self._on_soldi_cambiati)
	stats_manager.tempo_cambiato.connect(self._on_tempo_cambiato)
	stats_manager.evento_casuale_triggerato.connect(self._on_evento_casuale_triggerato)
	stats_manager.letto_pronto.connect(self._on_letto_pronto)

	_on_salute_mentale_cambiata(stats_manager.salute_mentale)
	_on_soldi_cambiati(stats_manager.soldi)
	_on_tempo_cambiato(stats_manager.ora, stats_manager.minuti, stats_manager.nomi_giorni_settimana[stats_manager.indice_giorno_settimana])


func _on_letto_pronto(letto_node_ref: Area2D):
	"""
	Questa funzione viene chiamata dallo StatsManager quando il nodo Letto si è registrato.
	Qui colleghiamo il segnale 'letto_interagito' del Letto alla nostra funzione di callback.
	"""
	if is_instance_valid(letto_node_ref): # Controlla che il riferimento al nodo sia valido
		letto_node_ref.connect("letto_interagito", _on_letto_interagito)
		print("HUD: Segnale 'letto_interagito' collegato con successo tramite StatsManager.")
	else:
		print("HUD ERROR: Il riferimento al nodo Letto passato da StatsManager non è valido.")


# --- Funzioni di Callback per i Segnali dello StatsManager (esistenti) ---

func _on_salute_mentale_cambiata(nuova_salute: int):
	"""
	Aggiorna il valore della TextureProgressBar che visualizza la salute mentale.
	"""
	salute_mentale_bar.value = nuova_salute

func _on_soldi_cambiati(nuovi_soldi: int):
	"""
	Aggiorna il testo della Label che visualizza la quantità di soldi.
	"""
	soldi_quantita_label.text = str(nuovi_soldi)

func _on_tempo_cambiato(nuova_ora: int, nuovi_minuti: int, nuovo_giorno_nome: String):
	"""
	Aggiorna il testo della Label dell'orologio.
	Formatta l'ora e i minuti con due cifre e uno zero iniziale (es. "08:05").
	Il testo finale sarà nel formato "LUN 08:30".
	"""
	var tempo_formattato = "%02d:%02d" % [nuova_ora, nuovi_minuti]
	orologio_label.text = "%s %s" % [nuovo_giorno_nome, tempo_formattato]

func _on_evento_casuale_triggerato(tipo_evento: String, messaggio: String, importo: int):
	"""
	Gestisce la visualizzazione di messaggi di notifica per eventi casuali.
	Utilizza la 'notifica_messaggio_label' per mostrare un messaggio temporaneo.
	"""
	var full_message = "Evento: %s! %s" % [tipo_evento, messaggio]
	if importo != 0:
		full_message += " (Importo: %d$)" % importo

	notifica_messaggio_label.text = full_message
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.5)

func _on_letto_interagito(messaggio: String, successo: bool):
	"""
	Gestisce la visualizzazione di messaggi di notifica relativi all'interazione con il letto.
	Mostra il messaggio fornito e lo fa scomparire.
	"""
	notifica_messaggio_label.text = messaggio
	notifica_messaggio_label.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notifica_messaggio_label, "modulate:a", 0.0, 1.0)
