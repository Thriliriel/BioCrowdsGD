extends Node3D

var f: int
var g: int
var h: int
var changePath: bool
var cell: Node3D
var parent: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	f = 0
	g = 0
	h = 0
	changePath = false
	cell = null
	parent = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
