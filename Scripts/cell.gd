extends Node3D

#is wall?
var isWall: bool
#markers
var markers = []
#neightbor cells
var neighborCells = []
#density of markers
var density: float
#qntMarkers
var qntMarkers: int
#marker radius, for distance
var markerRadius: float
#marker scene
@export var markerScene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	isWall = false
	density = 0.65
	qntMarkers = 0
	markerRadius = 0.1
	#when cell is created, also create its markers
	CreateMarkers(null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#dart throwing
func DartThrow(obstacles=null):
	#flag to break the loop if it is taking too long (maybe out of space)
	var flag = 0
	#print("Qnt create: " + str(qntMarkers))
	var i = 0
	while i < qntMarkers:
		var rng = RandomNumberGenerator.new()
		var x = randf_range (position.x, position.x + (scale.x/100))
		var y = randf_range (position.y, position.y + (scale.y/100))

		#print(self.id, x, y)

		#check distance from other markers to see if can instantiante
		var canInst = true
		for m in range (0, len(markers)):
			var distance = self.markers[m].position.distance_to(Vector3(x, y, 0))
			if distance < markerRadius:
				canInst = false
				break

		#if i can inst, still need to check if it does not fall inside an obstacle (later)
		#if canInst:
			#for it in range(0, len(obstacles)):
				#inside = self.Is_inside_polygon(obstacles[it].points, Vector3(x, y, 0))
				#if inside:
					#canInst = False
					#break

		#can i?
		if canInst:
			var newMarker = markerScene.instantiate()
			newMarker.position = Vector3(x, y, 0)
			markers.append(newMarker)
			add_child(newMarker)
			flag = 0
		#else, try again
		else:
			flag += 1
			i -= 1

		#if flag is above qntMarkers (*2 to have some more), break;
		if flag > qntMarkers * 2:
			#reset flag
			flag = 0
			#print(self.id)
			break

		i += 1
		
func CreateMarkers(obstacles):
	density *= ((scale.x/100)) / (2.0 * markerRadius)
	density *= ((scale.x/100)) / (2.0 * markerRadius)
	qntMarkers = floor(density)
	#print("Self - " + str(self.qntMarkers))
	DartThrow(obstacles)
	#print(markers[0].position)
	#print(len(markers))
	#if the ammount of markers is too low, declare as a wall
	if len(markers) < (qntMarkers/2):
		isWall = true
		
#find the neighbor cells
func FindNeighbor(allCells):
	#for each cell, check if the distance is lower or equal the hyp of the drawn square between the center of the cells
	for i in range(len(allCells)):
		var distance = position.distance_to(allCells[i].position)

		#if distance is zero, it is the same cell, ignore it
		if distance > 0:
			#now, check if the distance is inside the boundaries 
			#(for example: cellRadius = 2, max distance = sqrt(8) = 2.sqrt(2))
			if distance <= 0.1 + sqrt(pow((scale.x/100), 2) + pow((scale.x/100), 2)):
				neighborCells.append(allCells[i])

	#print(self.id, len(self.neighborCells))
