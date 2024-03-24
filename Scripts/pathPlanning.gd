extends Node3D
const NodePp = preload("res://Scripts/nodePP.gd")

var stopCondition: int
var nodesToCheck
var nodesChecked
var originNode: NodePp
var destinationNode: NodePp

# Called when the node enters the scene tree for the first time.
func _ready():
	stopCondition = 10000
	nodesToCheck = [] #NodeClass array
	nodesChecked = [] #NodeClass array
	originNode = NodePp.new()
	originNode._ready()
	destinationNode = NodePp.new()
	destinationNode._ready()
	print("Started!")

#find a path between two points
func FindPath(cellOrigin, cellDestination):
	#add the origin cell to the open list
	var newNode = NodePp.new()
	newNode.cell = cellOrigin
	nodesToCheck.append(newNode)

	#set the origin node
	originNode.cell = cellOrigin

	#set the destination node
	destinationNode.cell = cellDestination

	#to control the stop condition
	var nrIt = 0
	var foundPath = false
	#while there are nodes to check, repeat
	while len(nodesToCheck) > 0:
		nrIt += 1
		#order the list
		ReorderCheckList()

		#if wall, continue
		if nodesToCheck[0].cell.isWall:
			nodesToCheck.remove_at(0)
			continue

		#check the neighbour cells of the first node of the list and create their nodes
		FindNodes(nodesToCheck[0])
		
		var destinationId = destinationNode.cell.id

		#if arrived at destination, finished
		if nodesChecked[len(nodesChecked) - 1].cell.id == destinationId:
			foundPath = true
			break

		#if nrIt is bigger than the stop condition, byyye
		if nrIt > stopCondition:
			break

	#path
	var path = []

	#add the destination
	path.append(self.destinationNode.cell)

	#if found Path, make the reverse way to mount it
	#else, path is empty. Agent tries to go directly towards it
	if foundPath:
		var nodi = nodesChecked[len(nodesChecked) - 1]
		while nodi.parent != null:
			#add to path
			path.append(nodi.parent.cell)
			#update node with the parent
			nodi = nodi.parent

	#revert it
	path.reverse()

	#clear lists
	nodesChecked.clear()
	nodesToCheck.clear()

	#now the full path is ready, find only the corners (JUST IF WANT TO USE)
#      cornerPath = []
	#for i in range(0, len(path) - 1):
#          #difference between next position and actual position
#          nextDiffX = path[i + 1].position.x - path[i].position.x
#          nextDiffZ = path[i + 1].position.z - path[i].position.z

#          #difference between actual position and last position
#          lastDiffX = path[i].position.x - path[i - 1].position.x
#          lastDiffZ = path[i].position.z - path[i - 1].position.z

#          #if the difference just calculated is equal than the difference between actual position and last position, it is following a straight line. So, no need for corner
#          #otherwise, add it
#          if nextDiffX not lastDiffX or nextDiffZ not lastDiffZ:
#              cornerPath.append(path[i])

#      #if goal is not already in the list, add it
#      if cellDestination not in cornerPath:
#          cornerPath.append(cellDestination)

	#return cornerPath;
	return path

#reorder the nodes to check list, placing the lowest f at first
func ReorderCheckList():
	for i in range(0, len(nodesToCheck)):
		for j in range(0, len(nodesToCheck)):
			#if second one is higher??? (worked...) than the first one, change places
			if nodesToCheck[j].f > nodesToCheck[i].f:
				var auxNode = nodesToCheck[i]
				nodesToCheck[i] = nodesToCheck[j]
				nodesToCheck[j] = auxNode

#find nodes around the chosen node
func FindNodes(chosenNode):
	#iterate around the chosen node cell, using the neighborCells
	for i in range(0, len(chosenNode.cell.neighborCells)):
		#see it this node is not already in closed list
		var goAhead = true
		if chosenNode.cell.neighborCells[i] in nodesChecked:
			goAhead = false

		#if it is not
		if goAhead:
			#check if this node is not already on the open node list
			var alreadyInside = -1
			var z = 0
			while z < len(nodesToCheck):
				if nodesToCheck[z].cell.id == chosenNode.cell.neighborCells[i].id:
					alreadyInside = z
					break
				z += 1

			#if it is, check to see if this chosen path is better
			if alreadyInside > -1:
				#if the g value of chosenNode, plus the cost to move to this neighbour, is lower than the nodeG value, this path is better. So, update
				#otherwise, do nothing.
				var extraCost = 14
				if nodesToCheck[alreadyInside].cell.position.x == chosenNode.cell.position.x or nodesToCheck[alreadyInside].cell.position.y == chosenNode.cell.position.y:
					extraCost = 10

				if (chosenNode.g + extraCost) < nodesToCheck[alreadyInside].g:
					#re-calculate the values
					nodesToCheck[alreadyInside].g = (chosenNode.g + extraCost)
					nodesToCheck[alreadyInside].f = nodesToCheck[alreadyInside].g + nodesToCheck[alreadyInside].h
					#change parent
					nodesToCheck[alreadyInside].parent = chosenNode

			#else, just create it
			else:
				#create its node
				var newNode = NodePp.new()
				#initialize
				newNode.cell = chosenNode.cell.neighborCells[i]
				newNode.g = 14
				#set its values
				#h value
				newNode.h = EstimateDestination(newNode)
				#g value
				#if x or z axis is equal to the chosen node cell, it is hor/ver movement, so it costs only 10
				if newNode.cell.position.x == chosenNode.cell.position.x or newNode.cell.position.y == chosenNode.cell.position.y:
					newNode.g = 10

				#we update the cost of the cell, being it inversely proportional of the amount of markers found inside it
				#this way, we can make cells with less markers to be costier (emulating obstacles)
				newNode.g += newNode.cell.qntMarkers - len(newNode.cell.markers)

				#f, just sums h with g
				newNode.f = newNode.h + newNode.g
				#set the parent node
				newNode.parent = chosenNode

				#add this node in the open list
				nodesToCheck.append(newNode)		

	#done with this one
	nodesChecked.append(chosenNode)
	nodesToCheck.erase(chosenNode)

#estimate the h node value
func EstimateDestination(checkingNode):
	var manhattanWay = 0

	#since it is a virtual straight path, just sum up the differences in axis x and y
	var differenceX = abs(destinationNode.cell.position.x - checkingNode.cell.position.x)
	var differenceY = abs(destinationNode.cell.position.y - checkingNode.cell.position.y)

	#sum up and multiply by the weight (10)
	manhattanWay = int((differenceX + differenceY) * 10)

	return manhattanWay
