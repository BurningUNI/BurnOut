extends Control

@onready var label = $DialogoPanel/VBoxContainer/DialogoLabel
@onready var button_a = $DialogoPanel/VBoxContainer/SceltaA
@onready var button_b = $DialogoPanel/VBoxContainer/SceltaB
# QUESTO PERCORSO DEVE ESSERE ESATTO!
@onready var return_home_button = $DialogoPanel/TornaACasaButton 

var dialoghi = [
	{ # Indice 0
		"testo": "Ehi, ciao! Come va? Tutto bene oggi?",
		"scelte": [
			"Ciao! Sì, direi proprio di sì, giornata tranquilla.",
			"Non proprio benissimo, a dire la verità... Giornata un po' così."
		],
		"prossimo": [1, 2]
	},
	{ # Indice 1
		"testo": "Ottimo! Sono contento di sentirlo. C'è un motivo in particolare per cui sei di buon umore?",
		"scelte": [
			"Mah, niente di che, solo una bella sensazione generale.",
			"Sì, mi è arrivata una buona notizia in mattinata!"
		],
		"prossimo": [3, 4]
	},
	{ # Indice 2
		"testo": "Mi dispiace. Che è successo? Vuoi parlarne un po'?",
		"scelte": [
			"No, lascia stare, è una di quelle giornate storte e basta.",
			"Un po' di stanchezza e la solita mole di studio, niente di grave dai."
		],
		"prossimo": [5, 6]
	},
	{ # Indice 3
		"testo": "Fantastico! Beh, l'importante è che tu stia bene. Allora, a proposito di università...",
		"scelte": [
			"Giusto, parliamo di cose serie! Cosa mi dici della lezione di oggi?",
			"Uh, già, l'università... Che noia! Vabbè, dimmi."
		],
		"prossimo": [7, 7]
	},
	{ # Indice 4
		"testo": "Che bella cosa! Condividi, su! Fammi sorridere anche a me!",
		"scelte": [
			"Ho scoperto che il prof di Programmazione ha rimandato il compito!",
			"Era una cosa personale, ma mi ha dato una bella carica!"
		],
		"prossimo": [8, 8]
	},
	{ # Indice 5
		"testo": "Va bene, rispetto la tua privacy. Spero migliori in fretta, allora! Comunque, parlando di cose più leggere, hai visto la lezione di Analisi?",
		"scelte": [
			"Sì, ho provato a seguirla, ma era un bel mattone...",
			"L'ho persa, stavo recuperando il sonno arretrato."
		],
		"prossimo": [9, 10]
	},
	{ # Indice 6
		"testo": "Capisco, la stanchezza è una brutta bestia. Ma non preoccuparti, la sessione di esami è vicina, ce la faremo! Hai già pensato a come affrontare Analisi?",
		"scelte": [
			"Sto cercando di ripassare un po' tutti i concetti, per non lasciare buchi.",
			"No, aspetto l'ultimo minuto, come sempre!"
		],
		"prossimo": [11, 12]
	},
	{ # Indice 7
		"testo": "Parliamo pure, anche se la lezione di Analisi di oggi era tosta, eh? Il prof sembrava posseduto da un demone dei limiti!",
		"scelte": [
			"Ah, dici? Io ero già in modalità sopravvivenza dai primi dieci minuti.",
			"Ma sì, il solito show! Ormai ci sono abituato."
		],
		"prossimo": [13, 14]
	},
	{ # Indice 8
		"testo": "Grande notizia! Meno male, un po' di respiro ci voleva! Però poi non ci caschiamo, dobbiamo studiare sul serio!",
		"scelte": [
			"Certo, ora che ho un po' più di tempo mi organizzo meglio.",
			"Va bene, ma prima un giro al bar per festeggiare!"
		],
		"prossimo": [15, 16]
	},
	{ # Indice 9
		"testo": "Vero, ogni tanto il prof di Analisi ci mette alla prova! Però dai, se ci prepariamo bene, l'esame non dovrebbe essere impossibile. Come pensi di studiare?",
		"scelte": [
			"Mi concentrerò sulle formule e poi tanti esercizi.",
			"Provo a capire i concetti, le formule le imparo a memoria."
		],
		"prossimo": [17, 18]
	},
	{ # Indice 10
		"testo": "Ahah, tipico tuo! Ma la sessione di esami si avvicina, dobbiamo darci una mossa! Stai seguendo almeno Programmazione? Speriamo non ti sia sfuggita anche quella!",
		"scelte": [
			"Sì, quella la seguo, sto provando a fare qualche esercizio extra.",
			"Codice? No grazie, troppo complicato per me."
		],
		"prossimo": [19, 20]
	},
	{ # Indice 11
		"testo": "Ottimo approccio! Così non ti trovi con l'acqua alla gola all'ultimo. Hai già un piano di studio per Analisi?",
		"scelte": [
			"Sì, mi sono prefissato tot ore al giorno e revisione settimanale.",
			"Un piano? Io vado a sentimento, basta che funzioni!"
		],
		"prossimo": [21, 22]
	},
	{ # Indice 12
		"testo": "Ahah, il solito temerario! Spero ti vada bene, allora, ma sappi che studiare un po' alla volta aiuta davvero! Magari potremmo ripassare insieme qualche argomento ostico di Analisi?",
		"scelte": [
			"Potrebbe essere utile, mi sa che accetterò volentieri.",
			"Nah, preferisco soffrire da solo, così non disturbo nessuno."
		],
		"prossimo": [23, 24]
	},
	{ # Indice 13
		"testo": "Capisco, capisco... È che a volte tira fuori certi esercizi che ti fanno venire il mal di testa solo a guardarli. Però, se ci mettiamo sotto, ce la facciamo, no? Come pensi di affrontare la preparazione?",
		"scelte": [
			"Mi concentrerò sulle formule e poi tanti esercizi.",
			"Provo a capire i concetti, le formule le imparo a memoria."
		],
		"prossimo": [17, 18] 
	},
	{ # Indice 14
		"testo": "Ahah, il solito menefreghista! Ma stai seguendo almeno Programmazione? Spero tu non stia dormendo pure lì!",
		"scelte": [
			"Sì, quella la seguo, sto provando a fare qualche esercizio extra.",
			"Codice? No grazie, troppo complicato per me."
		],
		"prossimo": [19, 20] 
	},
	{ # Indice 15
		"testo": "Perfetto! Ma occhio a non esagerare con le celebrazioni, la strada è ancora lunga per la sessione di esami!",
		"scelte": [
			"Tranquillo, sono concentrato. Era solo un momento di gioia!",
			"Ma sì, festeggiamo ora e poi ci pensiamo domani!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 16
		"testo": "Capisco le priorità! L'importante è trovare il giusto equilibrio tra studio e 'nutrimento', eh! Non vorrei vederti svenire sui libri per fame!",
		"scelte": [
			"Esatto! La mente lavora meglio a stomaco pieno.",
			"O la mente lavora solo se c'è un panino in vista!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 17
		"testo": "Interessante! Tanti esercizi sono fondamentali per Analisi. Ti trovi meglio con i limiti o con le derivate?",
		"scelte": [
			"I limiti mi confondono un po', le derivate sono più intuitive.",
			"Odio tutto! Però i limiti mi stanno dando più filo da torcere."
		],
		"prossimo": [25, 26]
	},
	{ # Indice 18
		"testo": "Capire i concetti è la chiave! A memoria ti servirà per la prima parte, ma per gli esercizi è essenziale capirci qualcosa. Hai già qualche problema in particolare?",
		"scelte": [
			"Sì, le funzioni a più variabili sono un incubo per me.",
			"No, per ora tutto liscio, credo..."
		],
		"prossimo": [27, 28]
	},
	{ # Indice 19
		"testo": "Ottimo! Fare pratica è fondamentale per Programmazione. Che tipo di esercizi stai affrontando?",
		"scelte": [
			"Quelli sugli array e le strutture dati, un casino!",
			"Sto ripassando i concetti base, variabili, cicli... le fondamenta."
		],
		"prossimo": [29, 30]
	},
	{ # Indice 20
		"testo": "Peccato, ti perdi il bello! Magari un giorno cambierai idea, non è così male come sembra! Anche se i bug sono un po' una seccatura, l'esperienza è gratificante.",
		"scelte": [
			"Chi lo sa, magari in futuro... Mai dire mai!",
			"Nah, fa per voi 'smanettoni', non fa proprio per me."
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 21
		"testo": "Ottimo! La costanza premia sempre. Spero ti vada alla grande!",
		"scelte": [
			"Anche a te! In bocca al lupo per i tuoi esami!",
			"Dai che ce la facciamo entrambi, l'importante è crederci."
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 22
		"testo": "Ahah, un classico! L'importante è che alla fine il 'sentimento' ti porti al 18, o anche di più! Che ne dici di ripassare qualche teorema insieme?",
		"scelte": [
			"Sì, dai, mi fido di te, almeno non studio da solo.",
			"No, grazie, preferisco improvvisare fino alla fine."
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 23
		"testo": "Certo, quando vuoi! Per fortuna ci sono gli amici a darsi una mano in questo casino che è l'università. Qualche altra domanda?",
		"scelte": [
			"No, per ora è tutto chiaro. Grazie!",
			"No, ho la testa che fuma, direi che basta così!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 24
		"testo": "Ahah, capisco! Comunque, se cambi idea, io un ripasso lo farei volentieri. Ci si vede in giro allora!",
		"scelte": [
			"Sì, ci vediamo!",
			"Ciao, in bocca al lupo per i tuoi studi!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 25
		"testo": "I limiti richiedono un po' di pratica in più, è vero. Ma con le derivate sei messo bene! Se vuoi, possiamo fare qualche esercizio a riguardo.",
		"scelte": [
			"Sarebbe fantastico! Magari ripassiamo la prossima settimana?",
			"No, per ora mi arrangio, grazie!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 26
		"testo": "Capisco, a volte è frustrante. Non preoccuparti, con la pratica andrà meglio. Qualche altra materia che ti sta dando problemi?",
		"scelte": [
			"La Fisica è un osso duro, non mi entra in testa.",
			"Per ora no, solo Analisi mi sta facendo impazzire."
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 27
		"testo": "Le funzioni a più variabili sono un classico scoglio, non sei il solo! Potremmo provare a fare qualche esercizio insieme, magari ci illuminiamo a vicenda.",
		"scelte": [
			"Sì, volentieri! Magari fissiamo un giorno.",
			"No, preferisco studiare da solo, grazie."
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 28
		"testo": "Perfetto, vuol dire che hai un'ottima base! L'importante è non abbassare la guardia. Hai già pensato a quale progetto di Programmazione fare?",
		"scelte": [
			"Sì, stavo pensando a una piccola app per la gestione del tempo.",
			"Ancora no, aspetto l'ispirazione divina!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 29
		"testo": "Ah, array e strutture dati sono un classico! All'inizio sembrano un labirinto, ma con la pratica diventano la base di tutto. Se hai bisogno, possiamo fare qualche esercizio insieme.",
		"scelte": [
			"Sì, volentieri! Quei concetti mi mettono in crisi.",
			"No, preferisco capirci da solo, ci perdo il sonno ma ci riesco!"
		],
		"prossimo": [99, 99] # Fine Dialogo
	},
	{ # Indice 30
		"testo": "Ottimo! Le fondamenta sono cruciali in Programmazione. Costruisci bene le basi e poi il resto verrà da sé! Hai già provato a fare qualche piccolo programma?",
		"scelte": [
			"Sì, qualcosina di semplice, ma mi diverto.",
			"Ancora no, sono un po' bloccato dalla teoria."
		],
		"prossimo": [99, 99] # Fine Dialogo
	}
]

var index_corrente = 0

func _ready():
	print("DEBUG: Script dialogobar.gd avviato in _ready().") # Debugging: Messaggio di avvio
	MusicController.play_music(MusicController.track_library["bar"], "bar")
	# CONTROLLO CRITICO: Verifica che il pulsante sia stato trovato dal percorso
	if return_home_button:
		return_home_button.visible = false # Rendi il pulsante invisibile all'inizio
		return_home_button.text = "Torna a casa" # Imposta il testo del pulsante
		# Connetti il segnale 'pressed' del pulsante alla funzione che cambierà scena.
		# Questo viene fatto solo una volta, all'avvio del gioco.
		return_home_button.pressed.connect(_on_return_home_pressed)
		print("DEBUG: 'TornaACasaButton' trovato e inizializzato (nascosto).") # Debugging: Il pulsante è stato trovato
	else:
		# QUESTO È IL MESSAGGIO CHE VEDEVAMO PRIMA! Se lo vedi ancora, il percorso è sbagliato.
		push_error("ERRORE CRITICO: Nodo 'TornaACasaButton' NON TROVATO al percorso $DialogoPanel/TornaACasaButton! Il pulsante non funzionerà.")
		print("DEBUG: ERRORE: 'TornaACasaButton' non trovato o percorso errato.") # Debugging: Il pulsante non è stato trovato

	aggiorna_dialogo() # Avvia il dialogo iniziale
	print("DEBUG: aggiorna_dialogo() chiamato in _ready().") # Debugging: Chiamata iniziale


func aggiorna_dialogo():
	print("DEBUG: aggiorna_dialogo() chiamato. Indice corrente:", index_corrente) # Debugging: Stato del dialogo

	var d = dialoghi[index_corrente]
	label.text = d["testo"]

	# Rendi visibili i bottoni delle scelte del dialogo
	button_a.visible = true
	button_b.visible = true
	print("DEBUG: SceltaA e SceltaB resi visibili.") # Debugging: Bottoni delle scelte

	# Assicurati che il pulsante "Torna a casa" sia nascosto mentre il dialogo prosegue
	if return_home_button: # Controlla sempre che il nodo esista prima di usarlo
		return_home_button.visible = false 
		print("DEBUG: 'TornaACasaButton' nascosto (dialogo in corso).") # Debugging: Pulsante nascosto

	button_a.text = d["scelte"][0]
	button_b.text = d["scelte"][1]

	# Collega le funzioni per avanzare nel dialogo quando si clicca una scelta.
	# CONNECT_ONE_SHOT significa che la connessione viene usata una volta e poi rimossa.
	# Questo previene che un bottone chiami la funzione più volte per errore.
	button_a.pressed.connect(func(): avanza(d["prossimo"][0]), CONNECT_ONE_SHOT)
	button_b.pressed.connect(func(): avanza(d["prossimo"][1]), CONNECT_ONE_SHOT)
	print("DEBUG: Segnali di scelta riconnessi con CONNECT_ONE_SHOT.") # Debugging: Connessione segnali


func avanza(indice):
	print("DEBUG: avanza() chiamato. L'indice target è:", indice) # Debugging: Avanzamento dialogo

	if indice == 99: # Abbiamo deciso che l'indice 99 significa "fine del dialogo"
		print("DEBUG: Fine dialogo raggiunta (indice 99).") # Debugging: Fine dialogo
		label.text = "Beh dai io direi di tornare adesso, che domani ci aspetta una lunga giornata."
		button_a.visible = false # Nascondi i bottoni delle scelte
		button_b.visible = false
		print("DEBUG: SceltaA e SceltaB nascosti.") # Debugging: Bottoni nascosti

		# MOSTRA IL BOTTONE "TORNA A CASA"
		if return_home_button: # Controlla sempre che il nodo esista prima di usarlo
			return_home_button.visible = true 
			print("DEBUG: 'TornaACasaButton' è ora VISIBILE.") # Debugging: Pulsante visibile
		else:
			push_error("ATTENZIONE: return_home_button è null alla fine del dialogo. Non può essere mostrato.")
			print("DEBUG: ERRORE: 'TornaACasaButton' è null quando dovrebbe essere mostrato.") # Debugging: Pulsante non trovato

	else: # Se l'indice non è 99, il dialogo continua normalmente
		index_corrente = indice
		print("DEBUG: index_corrente aggiornato a:", index_corrente) # Debugging: Indice aggiornato

		# Assicurati che i bottoni delle scelte siano visibili se si continua il dialogo
		button_a.visible = true
		button_b.visible = true
		# E che il pulsante "Torna a casa" sia nascosto
		if return_home_button:
			return_home_button.visible = false 
		aggiorna_dialogo() # Continua con la prossima frase del dialogo

func _on_return_home_pressed():
	print("DEBUG: Pulsante 'Torna a casa' cliccato.") # Debugging: Click sul pulsante
	StatsManager.imposta_orario(23, 30)
	get_tree().change_scene_to_file("res://scenes/room.tscn")
	print("DEBUG: Tentativo di cambiare scena a 'res://scenes/room.tscn'.") # Debugging: Cambio scena in corso
