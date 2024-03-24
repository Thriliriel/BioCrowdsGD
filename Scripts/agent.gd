extends Node3D
const PathPlanning = preload("res://Scripts/pathPlanning.gd")

#id
var agentId: int
#agent's goal
var goal: Node3D
#goal position, for sub-goals
var goalPosition: Vector3
#path, with the subgoals
var path = []
#agent's radius
var radius: float
#agent's max speed
var maxSpeed: float
#agent's markers and vector
var markers = []
var vetorDistRelacaoMarcacao = []
#for the movement calculation
var denominadorW: bool
var valorDenominadorW: float
var m: Vector3
var s: float
var speedModule: float
var speed: Vector3
var cell: Node3D

# to check if agent is stuck
var lastDist = []

#using path planning?
var usePathPlanning: bool
var pathPlanning: PathPlanning

# Called when the node enters the scene tree for the first time.
func _ready():
	usePathPlanning = true
	cell = null
	goal = null
	speed = Vector3.ZERO
	m = Vector3.ZERO
	speedModule = 0
	denominadorW = false
	valorDenominadorW = 0
	goalPosition = Vector3.ZERO
	radius = 1
	maxSpeed = 1.2
	if usePathPlanning:
		pathPlanning = PathPlanning.new() #10000 = max iterations allowed to find a path
		pathPlanning._ready()
		path = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(position)
	pass
	
#clear agent´s informations
func ClearAgent():
	#re-set inicial values
	valorDenominadorW = 0
	vetorDistRelacaoMarcacao = []
	denominadorW = false
	m = Vector3.ZERO
	speed = Vector3.ZERO
	markers = []
	speedModule = 0
	if usePathPlanning:
		CheckSubGoalDistance()
	
#calculate W
func CalculateWeight(indiceRelacao):
	#calculate F (F is part of weight formula)
	var valorF = CalculateF(indiceRelacao)

	if not denominadorW:
		valorDenominadorW = 0

		#for each agent´s marker
		for i in range(0, len(vetorDistRelacaoMarcacao)):
			#calculate F for this k index, and sum up
			valorDenominadorW += CalculateF(i)
		denominadorW = true

	var retorno = valorF / valorDenominadorW
	#print(retorno)
	return retorno

#calculate F (F is part of weight formula)
func CalculateF(indiceRelacao):
	#distance between auxin´s distance and origin (dont know why origin...)
	var moduloY = vetorDistRelacaoMarcacao[indiceRelacao].distance_to(Vector3.ZERO)
	#distance between goal vector and origin (dont know why origin...)
	#print(Vector3.Sub_vec(goal.position, position))
	#print(Vector3.Zero())
	#print(Vector3.Distance(Vector3.Sub_vec(goal.position, position), Vector3.Zero()))
	#moduloX = Vector3.Distance(Vector3.Sub_vec(goal.position, position), Vector3.Zero())
	var moduloX = 1.0
	
	if moduloY < 0.00001:
		return 0
	var produtoEscalar = vetorDistRelacaoMarcacao[indiceRelacao].dot((goalPosition - position).normalized())
	
	var retorno = (1.0 / (1.0 + moduloY)) * (1.0 + ((produtoEscalar) / (moduloX * moduloY)))
	return retorno

#The calculation formula starts here
#the ideia is to find m=SUM[k=1 to n](Wk*Dk)
#where k iterates between 1 and n (number of auxins), Dk is the vector to the k auxin and Wk is the weight of k auxin
#the weight (Wk) is based on the degree resulting between the goal vector and the auxin vector (Dk), and the
#distance of the marker from the agent
func CalculateMotionVector():
	#for each agent´s marker
	s = 0.0
	for i in range(0, len(vetorDistRelacaoMarcacao)):
		var valorW = CalculateWeight(i)
		if valorDenominadorW < 0.0001:
			valorW = 0
		s += valorW

		#sum the resulting vector * weight (Wk*Dk)
		var multX = vetorDistRelacaoMarcacao[i].x * maxSpeed * valorW
		var multY = vetorDistRelacaoMarcacao[i].y * maxSpeed * valorW
		var multZ = vetorDistRelacaoMarcacao[i].z * maxSpeed * valorW
		m = m + Vector3(multX, multY, multZ)

	#print(m.x, m.y, m.z)
	#print("weights", s)

#calculate speed vector
func CalculateSpeed():
	var moduloM = m.distance_to(Vector3.ZERO)

	#multiply for PI
	s = moduloM * 3.14
	var thisMaxSpeed = maxSpeed

	#if it is bigger than maxSpeed, use maxSpeed instead
	if s > thisMaxSpeed:
		s = thisMaxSpeed

	speedModule = s

	if moduloM > 0.0001:
		#calculate speed vector
		var newX = s * (m.x / moduloM)
		var newY = s * (m.y / moduloM)
		var newZ = s * (m.z / moduloM)
		speed = Vector3(newX, newY, newZ)
	else:
		#else, he is idle
		speed = Vector3.ZERO
		
#check markers on a cell
func CheckMarkersCell(checkCell):
	#get all markers on cell
	var cellMarkers = checkCell.markers

	#iterate all cell markers to check distance between markers and agent
	for i in range(0, len(cellMarkers)):
		#see if the distance between this agent and this marker is smaller than the actual value, and inside agent radius
		var distance = position.distance_to(cellMarkers[i].position)
		#we also test if it is already inside someone's personal space
		if distance < cellMarkers[i].minDistance and distance <= radius:
			#take the marker!!
			#if this marker already was taken, need to remove it from the agent who had it
			if cellMarkers[i].taken != null and cellMarkers[i].taken.agentId != agentId:
				var otherAgent = cellMarkers[i].taken
				otherAgent.markers.remove(cellMarkers[i])

			#marker is taken
			cellMarkers[i].taken = self
			#update min distance
			cellMarkers[i].minDistance = distance

			#update my markers
			markers.append(cellMarkers[i])
			
#find all markers near him (Voronoi Diagram)
#call this method from Biocrowds, to make it sequential for each agent
func FindNearMarkers():
	#clear all agents markers, to start again for this iteration
	markers.clear()
	markers = []

	#check all markers on agent's cell
	CheckMarkersCell(cell)

	#distance from agent to cell, to define agent new cell
	var distanceToCell = position.distance_to(cell.position)
	var cellToChange = cell
	
	#iterate through neighbors of the agent cell
	for i in range(0, len(cell.neighborCells)):
		if i >= len(cell.neighborCells):
			break

		#check all markers on this cell
		CheckMarkersCell(cell.neighborCells[i]) 

		#see distance to this cell
		#if it is lower, the agent is in another(neighbour) cell
		var distanceToNeighbourCell = position.distance_to(cell.neighborCells[i].position)
		if distanceToNeighbourCell < distanceToCell:
			distanceToCell = distanceToNeighbourCell
			cellToChange = cell.neighborCells[i]

		cell = cellToChange

		#add to cell passed agents (FOR DENSITY LATER)
		#cell.AddPassedAgent(id)
		
#walk
#DEVE DAR PARA FAZER ESSE MOVIMENTO MAIS FLUIDO, QUE NEM NA UNITY
func Walk(timeStep):
	var newX = speed.x * timeStep
	var newY = speed.y * timeStep
	var newZ = speed.z * timeStep
	position += Vector3(newX, newY, newZ)

#check the sub-goal distance
func CheckSubGoalDistance():
	#just check if the sub-goal is not the actual goal
	if goalPosition != goal.position:
		var distanceSubGoal = position.distance_to(goalPosition)
		if distanceSubGoal < radius and len(path) > 1:
			path.remove_at(0)
			goalPosition = Vector3(path[0].position.x, path[0].position.y, path[0].position.z)
		elif distanceSubGoal < radius:
			goalPosition = goal.position
			
func FindPath():
	path = pathPlanning.FindPath(cell, goal.cell)
	var pt = path[0]
	goalPosition = Vector3(pt.position.x, pt.position.y, pt.position.z)
			
func GetCell():
	return cell
	
func SetCell(newCell):
	cell = newCell
