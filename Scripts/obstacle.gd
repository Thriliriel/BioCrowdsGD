extends Node3D

var points = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#set the points (for now, square)
	var diffX = scale.x / 200
	var diffY = scale.y / 200
	points.append(Vector3(position.x-diffX, position.y+diffY, position.z))
	points.append(Vector3(position.x+diffX, position.y+diffY, position.z))
	points.append(Vector3(position.x+diffX, position.y-diffY, position.z))
	points.append(Vector3(position.x-diffX, position.y-diffY, position.z))

	#print(position)
	#print(scale)
	#print(points)
