extends Node3D

#owner
var taken: Node3D
#min distance
var minDistance: int

# Called when the node enters the scene tree for the first time.
func _ready():
	minDistance = 5
	taken = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
#set an owner
func SetOwner(own):
	taken = own
	
#unset an owner
func UnsetOwner():
	taken = null
	
#reset default values
func ResetMarker():
	taken = null
	minDistance = 5
