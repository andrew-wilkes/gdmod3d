extends Resource

class_name Settings

const FILE_NAME = "user://settings.tres"

@export var current_file = "project.rsc"
@export var last_dir = ""
@export var date_format = "YYYY-MM-DD"

func save_data():
	var _result = ResourceSaver.save(self, FILE_NAME)


func load_data():
	if ResourceLoader.exists(FILE_NAME):
		return ResourceLoader.load(FILE_NAME)
	else:
		last_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		return self
