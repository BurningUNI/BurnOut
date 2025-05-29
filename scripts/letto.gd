# Letto.gd
extends Area2D

# Orario minimo per poter andare a dormire (21:30 = 21 ore, 30 minuti)
const ORA_MINIMA_PER_DORMIRE = 21
const MINUTI_MINIMI_PER_DORMIRE = 30

# Variabile per tenere traccia se il giocatore è nell'area del letto
var player_in_range = false

# Segnale da emettere quando il letto viene interagito (successo o fallimento)
# Questo segnale sarà ascoltato dalla HUD per mostrare messaggi
signal letto_interagito(messaggio: String, successo: bool)

func _ready():
	# Collega i segnali 'body_entered' e 'body_exited' dell'Area2D.
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	# Registra questo nodo Letto con il GameState
	GameState.register_bed(self)


func _process(delta):
	# Controlla se il giocatore è nell'area e se ha premuto l'azione "interact" (tasto Spazio).
	if player_in_range and Input.is_action_just_pressed("interact"): # <--- MODIFICATO QUI: "interact"
		tentad_di_dormire()

func _on_body_entered(body: Node2D):
	# Quando un corpo (PhysicsBody2D) entra nell'area del letto.
	if body.name == "Player": # <-- IMPORTANTE: Cambia "Player" se il tuo nodo giocatore ha un nome diverso
		player_in_range = true
		print("Player è vicino al letto.")
		# Emette un messaggio informativo alla HUD per mostrare "Premi [SPAZIO] per dormire"
		emit_signal("letto_interagito", "Premi [SPAZIO] per dormire.", false) # Il messaggio visivo non cambia, solo il comando

func _on_body_exited(body: Node2D):
	# Quando un corpo esce dall'area del letto.
	if body.name == "Player": # <-- IMPORTANTE: Cambia "Player" se il tuo nodo giocatore ha un nome diverso
		player_in_range = false
		print("Player ha lasciato il letto.")
		# Emette un messaggio vuoto alla HUD per nascondere il suggerimento
		emit_signal("letto_interagito", "", false)

func tentad_di_dormire():
	var ora_attuale = GameState.ora
	var minuti_attuali = GameState.minuti

	# Logica per controllare se è abbastanza tardi per dormire (dopo le 21:30)
	if ora_attuale > ORA_MINIMA_PER_DORMIRE or \
	   (ora_attuale == ORA_MINIMA_PER_DORMIRE and minuti_attuali >= MINUTI_MINIMI_PER_DORMIRE):
		
		# È abbastanza tardi: fai dormire il giocatore e avanza il tempo!
		print("Andando a dormire...")
		GameState.ora = 7 # Sveglia alle 7 del mattino
		GameState.minuti = 0 # Minuti a 0
		GameState.giorno += 1 # Avanza al giorno successivo
		
		# Aggiorna l'indice del giorno della settimana
		GameState.indice_giorno_settimana = (GameState.indice_giorno_settimana + 1) % 7

		# Emetti il segnale per aggiornare la HUD con il nuovo tempo e salva lo stato
		GameState.emit_signal("tempo_cambiato", GameState.ora, GameState.minuti, GameState.nomi_giorni_settimana[GameState.indice_giorno_settimana])
		GameState.save_game() # Salva lo stato del gioco

		# Emetti un segnale per la HUD per mostrare un messaggio di successo
		emit_signal("letto_interagito", "Hai dormito bene! Nuovo giorno: %s Giorno %d" % [GameState.nomi_giorni_settimana[GameState.indice_giorno_settimana], GameState.giorno], true)

	else:
		# Troppo presto per dormire
		var messaggio_troppo_presto = "È troppo presto per andare a dormire! Riprova dopo le %02d:%02d." % [ORA_MINIMA_PER_DORMIRE, MINUTI_MINIMI_PER_DORMIRE]
		print(messaggio_troppo_presto)
		# Emetti un segnale per la HUD per mostrare il messaggio di avviso
		emit_signal("letto_interagito", messaggio_troppo_presto, false)
