extends Control

# ──────────────  NODI UI  ──────────────
@onready var dialogo_label   : Label  = $DialogBox/DialogoLabel
@onready var btn_analisi     : Button = $DialogBox/VBoxContainer/analisi1
@onready var btn_programma   : Button = $DialogBox/VBoxContainer/programmazione1

@onready var domanda_box     : Control = $DomandaBox
@onready var domanda_label   : Label   = $DomandaBox/DomandaLabel
@onready var rispostaA       : Button  = $DomandaBox/rispostaA
@onready var rispostaB       : Button  = $DomandaBox/rispostaB

# ──────────────  DOMANDE  ──────────────
const ESAMI := {
	"analisi": [
		{ "testo":"Quanto fa la derivata di x^2?", "A":"2x",   "B":"x^2",   "corretta":"A" },
		{ "testo":"Qual è l'integrale di 1/x?",   "A":"ln|x|", "B":"1/x^2", "corretta":"A" },
	],
	"programmazione": [
		{ "testo":"Quale parola chiave definisce una funzione in Python?", "A":"def",   "B":"func",   "corretta":"A" },
		{ "testo":"Come si stampa qualcosa in console?",                  "A":"echo()", "B":"print()", "corretta":"B" },
	],
}

var esami_coda      : Array[String] = []   # esami da svolgere (queue)
var esame_corrente  : String        = ""   # esame in corso
var domande_correnti: Array         = []   # domande di quell’esame
var indice_domanda  : int           = 0    # domanda corrente

# ──────────────  READY  ──────────────
func _ready() -> void:
	domanda_box.visible = false
	rispostaA.pressed.connect(check_risposta.bind("A"))
	rispostaB.pressed.connect(check_risposta.bind("B"))
	mostra_scelta_iniziale()

# ───────────  SCELTA PRIMO ESAME  ───────────
func mostra_scelta_iniziale() -> void:
	dialogo_label.text = "Scegli quale esame affrontare per primo:"
	btn_analisi.visible       = true
	btn_programma.visible     = true
	$DialogBox.visible        = true
	domanda_box.visible       = false

	btn_analisi.pressed.connect(func():
		esami_coda = ["analisi", "programmazione"]
		start_next_exam()
	, CONNECT_ONE_SHOT)

	btn_programma.pressed.connect(func():
		esami_coda = ["programmazione", "analisi"]
		start_next_exam()
	, CONNECT_ONE_SHOT)

# ───────────  AVVIA / PASSA ESAME  ───────────
func start_next_exam() -> void:
	if esami_coda.is_empty():
		get_tree().change_scene_to_file("res://scenes/room.tscn")
		return

	esame_corrente      = esami_coda.pop_front()
	domande_correnti    = ESAMI[esame_corrente]
	indice_domanda      = 0

	$DialogBox.visible  = false
	domanda_box.visible = true
	mostra_domanda()

# ───────────  LOOP DOMANDE  ───────────
func mostra_domanda() -> void:
	if indice_domanda < domande_correnti.size():
		var d = domande_correnti[indice_domanda]
		domanda_label.text = d["testo"]
		rispostaA.text     = d["A"]
		rispostaB.text     = d["B"]
		dialogo_label.text = ""       # pulisce eventuali messaggi
	else:
		gestisci_fine_esame()

# ───────────  CHECK RISPOSTA  ───────────
func check_risposta(risposta_scelta:String) -> void:
	var d = domande_correnti[indice_domanda]
	if risposta_scelta == d["corretta"]:
		indice_domanda += 1
		mostra_domanda()
	else:
		# risposta errata → ricomincia lo stesso esame
		dialogo_label.text  = "Risposta sbagliata! Ricominciamo l’esame di " + esame_corrente + "."
		indice_domanda      = 0
		$DialogBox.visible  = true
		domanda_box.visible = false
		await get_tree().create_timer(2.0).timeout
		$DialogBox.visible  = false
		domanda_box.visible = true
		mostra_domanda()

# ───────────  FINE ESAME  ───────────
func gestisci_fine_esame() -> void:
	if esami_coda.is_empty():
		get_tree().change_scene_to_file("res://scenes/winscreen.tscn")
	else:
		var prossimo = esami_coda[0]
		dialogo_label.text  = "Hai superato " + esame_corrente + "! Passiamo a " + prossimo + "..."
		$DialogBox.visible  = true
		domanda_box.visible = false
		await get_tree().create_timer(2.0).timeout
		start_next_exam()
