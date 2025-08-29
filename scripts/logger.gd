extends RefCounted

class_name Logger

var items = []

func add_item(v):
	items.append(JSON.stringify(v))


func write_to_file(fn = "res://docs/log.txt"):
	var file = FileAccess.open(fn, FileAccess.WRITE)
	file.store_string("\n".join(items))
