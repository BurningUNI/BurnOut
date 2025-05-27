extends RichTextLabel

@export var testo_completo := ""
@export var velocità_scrittura := 0.03

var carattere_attuale := 0
var timer := 0.0

func _ready():
	bbcode_enabled = true
	text = ""
	carattere_attuale = 0
	timer = 0.0

func _process(delta):
	if carattere_attuale < testo_completo.length():
		timer += delta
		if timer >= velocità_scrittura:
			text += testo_completo[carattere_attuale]
			carattere_attuale += 1
			timer = 0.0
