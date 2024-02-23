extends Node

#to handle file operations

#save a file
func SaveFile(fileName, content):
	pass

#load a file and return the json object
func LoadFile(fileName):	
	var json_as_text = FileAccess.get_file_as_string(fileName)
	var json_as_dict = JSON.parse_string(json_as_text)
	
	return json_as_dict
