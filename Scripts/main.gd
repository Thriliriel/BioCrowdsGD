extends Node3D

#camera speed
@export var cameraSpeed: int
@export var cellScene: PackedScene
#cellSize
var cellSize = Vector3(0, 0, 0)
#mapSize
var mapSize = Vector3(30, 30, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	#cells holder
	var cells = $Cells
	
	var posX = 0
	var posY = 0
	for i in range(0, mapSize.x):
		posY = 0
		for j in range(0, mapSize.y):
			#instantiate new cell
			var newCell = cellScene.instantiate()
			newCell.position = Vector3(posX, posY, newCell.position.z)
			#print(str(newCell.position.x) + "--" + str(newCell.position.y))
			#add to the scene
			cells.add_child(newCell)
			
			#if we do not have the cellSize yet, get it
			if cellSize == Vector3.ZERO:
				cellSize = newCell.scale / 100
			
			posY += cellSize.y
		posX += cellSize.x

	#print(cells.get_child_count())
	
	#camera position
	$Camera.position = Vector3(mapSize.x/2, mapSize.y/2, $Camera.position.z)

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
