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
#obstacles holder
var obsHolder: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	isWall = false
	density = 0.65
	qntMarkers = 0
	markerRadius = 0.1
	#when cell is created, also create its markers
	#get obstacles
	var obs = obsHolder.get_children()
	CreateMarkers(obs)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#dart throwing
func DartThrow(obstacles):
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
		if canInst:
			for it in range(0, len(obstacles)):
				var inside = Is_inside_polygon(obstacles[it].points, Vector3(x, y, 0))
				if inside:
					canInst = false
					break

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

# Given three collinear points p, q, r, 
# the function checks if point q lies
# on line segment 'pr'
func OnSegment(p, q, r):
	
	if ((q.x <= max(p.x, r.x)) &
		(q.x >= min(p.x, r.x)) &
		(q.y <= max(p.y, r.y)) &
		(q.y >= min(p.y, r.y))):
		return true
		
	return false

# To find orientation of ordered triplet (p, q, r).
# The function returns following values
# 0 --> p, q and r are collinear
# 1 --> Clockwise
# 2 --> Counterclockwise
func Orientation(p, q, r):
	
	var val = (((q.y - p.y) *
			(r.x - q.x)) -
			((q.x - p.x) *
			(r.y - q.y)))
		
	if val == 0:
		return 0
	if val > 0:
		return 1 # Collinear
	else:
		return 2 # Clock or counterclock

func DoIntersect(p1, q1, p2, q2):     
	# Find the four orientations needed for 
	# general and special cases
	var o1 = Orientation(p1, q1, p2)
	var o2 = Orientation(p1, q1, q2)
	var o3 = Orientation(p2, q2, p1)
	var o4 = Orientation(p2, q2, q1)

	# General case
	if (o1 != o2) and (o3 != o4):
		return true
	
	# Special Cases
	# p1, q1 and p2 are collinear and
	# p2 lies on segment p1q1
	if (o1 == 0) and (OnSegment(p1, p2, q1)):
		return true

	# p1, q1 and p2 are collinear and
	# q2 lies on segment p1q1
	if (o2 == 0) and (OnSegment(p1, q2, q1)):
		return true

	# p2, q2 and p1 are collinear and
	# p1 lies on segment p2q2
	if (o3 == 0) and (OnSegment(p2, p1, q2)):
		return true

	# p2, q2 and q1 are collinear and
	# q1 lies on segment p2q2
	if (o4 == 0) and (OnSegment(p2, q1, q2)):
		return true

	return false

# Returns true if the point p lies 
# inside the polygon[] with n vertices
func Is_inside_polygon(points, p):
	
	var n = len(points)
	
	# There must be at least 3 vertices
	# in polygon
	if n < 3:
		return false
		
	# Create a point for line segment
	# from p to infinite
	var extreme = Vector3(9223372036854775807, p.y, 0)
	var count = 0
	var i = 0
	
	while true:
		var next = (i + 1) % n
		
		# Check if the line segment from 'p' to 
		# 'extreme' intersects with the line 
		# segment from 'polygon[i]' to 'polygon[next]'
		if (DoIntersect(points[i],
						points[next],
						p, extreme)):
							
			# If the point 'p' is collinear with line 
			# segment 'i-next', then check if it lies 
			# on segment. If it lies, return true, otherwise false
			if Orientation(points[i], p,
							points[next]) == 0:
				return OnSegment(points[i], p,
									points[next])
								
			count += 1
			
		i = next
		
		if (i == 0):
			break
		
	# Return true if count is odd, false otherwise
	return (count % 2 == 1)
