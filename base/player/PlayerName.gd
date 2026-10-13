extends Label3D

@export var player_name: String = "":
	set(value):
		player_name = value
		if is_node_ready():
			text = player_name

func _ready() -> void:
	# 1. Change the type hint to bool for steamInit()
	var init: bool = Steam.steamInit() 
	var is_running: bool = Steam.isSteamRunning()

	if not is_running:
		print("Steam no running :(")
		text = "Steam App Not Open"
		return

	print("Steam client is running on PC.")
	
	# 2. Check if the boolean initialization succeeded
	if init:
		print("GodotSteam successfully connected!")
		player_name = Steam.getPersonaName()
		text = player_name
	else:
		print("Initialization Failed! Make sure steam_appid.txt is set up.")
		text = "Steam Init Failed"

	print("Player's name display: ", text)
