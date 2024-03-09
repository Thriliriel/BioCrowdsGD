extends Node3D

#camera speed
@export var cameraSpeed: int
@export var cellScene: PackedScene
@export var goalScene: PackedScene
@export var agentScene: PackedScene
@export var obsScene: PackedScene
#cellSize
var cellSize = Vector3(0, 0, 0)
#mapSize
var mapSize = Vector3(30, 30, 0)
#all agents (should make it faster, since it does not need to find them each frame)
var agents = []
#all cells (should make it faster, since it does not need to find them each frame)
var cells = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#get the information from the config file
	var result = Filehandler.LoadFile("Config.json")
	result = result["simulation"]
	
	#update mapSize according the config file
	mapSize = Vector3(result["environment"]["size"][0], result["environment"]["size"][1], result["environment"]["size"][2])
	
	#obstacles
	#obstacles holder
	var obsHolder = $Obstacles
	
	#obstacles from file
	var obstacles = result["obstacles"]
	
	#for each obstacle
	for obs in obstacles:		
		var newObs = obsScene.instantiate()
		
		var transf = obs["transform"]
		
		newObs.position = Vector3(transf["position"][0], transf["position"][1], transf["position"][2])
		newObs.rotation = Vector3(transf["rotation"][0], transf["rotation"][1], transf["rotation"][2])
		newObs.scale = Vector3(transf["localScale"][0]*newObs.scale.x, transf["localScale"][1]*newObs.scale.y, transf["localScale"][2]*newObs.scale.z)
		
		obsHolder.add_child(newObs)
	
	#cells holder
	var cellsHolder = $Cells
	
	var posX = 0
	var posY = 0
	for i in range(0, mapSize.x):
		posY = 0
		for j in range(0, mapSize.y):
			#instantiate new cell
			var newCell = cellScene.instantiate()
			newCell.position = Vector3(posX, posY, newCell.position.z)
			#print(str(newCell.position.x) + "--" + str(newCell.position.y))
			#set the obstacle holder
			newCell.obsHolder = obsHolder
			cells.append(newCell)
			#add to the scene
			cellsHolder.add_child(newCell)
			
			#if we do not have the cellSize yet, get it
			if cellSize == Vector3.ZERO:
				cellSize = newCell.scale / 100
			
			posY += cellSize.y
		posX += cellSize.x

	#print(cells.get_child_count())
	
	#for each cell, find its neighbors
	for i in range(0, len(cells)):
		cells[i].FindNeighbor(cells)
	
	#camera position
	$Camera.position = Vector3(mapSize.x/2, mapSize.y/2, $Camera.position.z)
	
	#put goals, according the config file
	var configGoals = result["goals"]
	for g in configGoals:		
		var goal = goalScene.instantiate()
		var chosenCell = FindNearestCell(Vector3(g["position"][0], g["position"][1], g["position"][2]))
		$Goals.add_child(goal)
		goal.SetCell(chosenCell)
		goal.position = chosenCell.position
	
	#put agents, according the spawn points
	var configAgents = result["spawnAreas"]
	for a in configAgents:
		#how many agents?
		var qntAgents = int(a["agent_count"])
		#goal list
		var goalList = a["goal_list"]
		#position
		var startPos = Vector3(a["transform"]["position"][0], a["transform"]["position"][1], a["transform"]["position"][2])
		
		#for each agent, spawn
		for ag in qntAgents:
			var agent = agentScene.instantiate()
			var chosenCell = FindNearestCell(startPos)
			$Agents.add_child(agent)
			agent.SetCell(chosenCell)
			agent.position = chosenCell.position
			agent.goal = $Goals.get_children()[goalList[0]] #ONLY ONE GOAL SO FAR!!
			agent.goalPosition = agent.goal.position
			agents.append(agent)	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#camera movement
	var velocity = Vector3.ZERO # The camera's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y -= 1
	if Input.is_action_pressed("move_up"):
		velocity.y += 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * cameraSpeed
		
	$Camera.position += velocity * delta
	#end camera movement
	
	#if no agent left, done
	if len(agents) > 0:
		#walking loop
		#for each agent, we reset their info
		for i in range(0, len(agents)):
			agents[i].ClearAgent()
			
		#reset the markers
		for i in range(0, len(cells)):
			for j in range(0, len(cells[i].markers)):
				cells[i].markers[j].ResetMarker()
				
		#find nearest markers for each agent
		for i in range(0, len(agents)):
			agents[i].FindNearMarkers()
			
		#/*to find where the agent must move, we need to get the vectors from the agent to each auxin he has, and compare with 
	#   the vector from agent to goal, generating a angle which must lie between 0 (best case) and 180 (worst case)
	#   The calculation formula was taken from the Bicho´s mastery tesis and from Paravisi algorithm, all included
	#   in AgentController.
	#   */

	#   /*for each agent, we:
	#   1 - verify existence
	#   2 - find him 
	#   3 - for each marker near him, find the distance vector between it and the agent
	#   4 - calculate the movement vector (CalculateMotionVector())
	#   5 - calculate speed vector (CalculateSpeed())
	#   6 - walk (Walk())
	#   7 - verify if the agent has reached the goal. If so, destroy it
	#   */
	
		#keep agents to remove after the iteration
		var agentsToKill = []
		var i = 0
		while i < len(agents):
			var agentMarkers = agents[i].markers

			#vector for each marker
			for j in range(0, len(agentMarkers)):
				#add the distance vector between it and the agent
				#print (agents[i].position, agentMarkers[j].position)
				#print (agents[i].position - agentMarkers[j].position)
				agents[i].vetorDistRelacaoMarcacao.append(agentMarkers[j].position - agents[i].position)

			#print("total", len(agents[i].vetorDistRelacaoMarcacao))
			#calculate the movement vector
			agents[i].CalculateMotionVector()

			#print(agents[i].m)
			#calculate speed vector
			agents[i].CalculateSpeed()

			#walk
			agents[i].Walk(delta)

			#write in file
			#resultFile.write(str(agents[i].id) + ";" + str(agents[i].position.x) + ";" + str(agents[i].position.y) + ";" + str(agents[i].position.z) + "\n")

			#verify agent position, in relation to the goal. If arrived, bye
			var dist = agents[i].goal.position.distance_to(agents[i].position)
			#print(agents[i].id, " -- Dist: ", dist, " -- Radius: ", agents[i].radius, " -- Agent: ", agents[i].position.x, agents[i].position.y)
			#print(agents[i].speed.x, agents[i].speed.y)
			if dist < agents[i].radius / 4:
				agentsToKill.append(i)

			#update lastdist (max = 5)
			if len(agents[i].lastDist) == 5:
				agents[i].lastDist.remove_at(0)

			agents[i].lastDist.append(dist)

			#check them all
			var qntFound = 0
			for ck in agents[i].lastDist:
				if ck == dist:
					qntFound += 1

			#if distances does not change, assume agent is stuck
			if qntFound == 5:
				agentsToKill.append(i)

			i += 1
		#end walking loop
	
		#die!
		if len(agentsToKill) > 0:
			for k in range(0, len(agentsToKill)):
				agents.remove_at(agentsToKill[k])

#find the nearest cell, given the position
func FindNearestCell(givenPosition):
	var chosenCell = null
	var distance = mapSize.x + mapSize.y
	
	var cells = $Cells.get_children()
	
	for c in cells:
		var thisDist = c.position.distance_to(givenPosition)
		if thisDist < distance:
			distance = thisDist
			chosenCell = c
			
		#if distance is lower than the cellSize, do not need to keep looking
		if distance < cellSize.x:
			break
	
	return chosenCell
	
