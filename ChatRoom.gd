extends Control

onready var joinBtn = $Options/JoinBtn
onready var leaveBtn = $Options/LeaveBtn
onready var hostBtn = $Options/HostBtn
onready var ipInput = $Options/IpInput

onready var chatInput = $Panel/ChatInput
onready var chatTxt = $Panel/ChatTxt

const PORT = 4646
const MAX_USERS = 4 # Not including host!

# Client or Host connection
var connection = null

func _ready():
	
	# Disable elements by default:
	leaveBtn.disabled = true;
	chatInput.editable = false;
	
	# Listen for connection signals
	get_tree().connect("connected_to_server", self, "enterRoom")
	get_tree().connect("network_peer_connected", self, "userEntered")
	get_tree().connect("network_peer_disconnected", self, "userExited")
	get_tree().connect("server_disconnected", self, "onDisconnected")
	
	# Setup Buttons
	hostBtn.connect("pressed", self, "hostRoom")
	joinBtn.connect("pressed", self, "joinRoom")
	leaveBtn.connect("pressed", self, "leaveRoom")

func _input(event):
	if not event is InputEventKey:
		return
	
	if event.pressed and event.scancode == KEY_ENTER:
		sendMessage()

func sendMessage():
	var message = chatInput.text
	chatInput.text = ""
	
	var id = get_tree().get_network_unique_id()
	rpc("receiveMessage", id, message)

sync func receiveMessage(id, message):
	addMessage("[" + str(id) + "]: " + message)

func hostRoom():
	connection = NetworkedMultiplayerENet.new()
	connection.create_server(PORT, MAX_USERS)
	get_tree().set_network_peer(connection)
	
	addMessage("Room Created")
	enterRoom()

func joinRoom():
	var ip = ipInput.text
	
	connection = NetworkedMultiplayerENet.new()
	connection.create_client(ip, PORT)
	get_tree().set_network_peer(connection)

func enterRoom():
	# Enable / Disable UI
	chatInput.editable = true
	leaveBtn.disabled = false
	joinBtn.disabled = true
	hostBtn.disabled = true
	ipInput.editable = false
	
	addMessage("Joined Room")

func leaveRoom():
	# Enable / Disable UI
	chatInput.editable = false
	leaveBtn.disabled = true
	joinBtn.disabled = false
	hostBtn.disabled = false
	ipInput.editable = true
	
	addMessage("Left Room")
	
	# Disconnect...
	connection.close_connection()
	get_tree().set_network_peer(null)
	connection = null

func userEntered(id):
	addMessage(str(id) + " joined the room")

func userExited(id):
	addMessage(str(id) + " left the room")

func onDisconnected():
	addMessage("Disconnected from server")
	leaveRoom()

func addMessage(message):
	chatTxt.text += message + "\n";
	
	# Manual scroll the text-edit (which has limited scroll features!)
	# RichText labels have more scroll options!
	chatTxt.cursor_set_line(chatTxt.get_line_count(), true, true)
