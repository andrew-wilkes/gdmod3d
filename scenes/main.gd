extends VBoxContainer
class_name Main

signal add_selection(id)
signal load_obj_file(txt)
signal save_obj_file(file)

enum { NO_ACTION, NEW, OPEN, SAVE, SAVE_AS, IMPORT, QUIT, ABOUT, LICENCES }

var update_timer = 0
var state = NO_ACTION
var menu_action = NO_ACTION

@onready var file_menu = find_child("File").get_popup()
@onready var edit_menu = find_child("Edit").get_popup()
@onready var add_menu = find_child("Add").get_popup()
@onready var help_menu = find_child("Help").get_popup()
@onready var file_dialog = find_child("FileDialog")
@onready var alert = $Alert

func _ready() -> void:
	Globals.perspective_button = %PerspectiveButton
	Globals.vertex_button = %VertexButton
	Globals.edge_button = %EdgeButton
	Globals.face_button = %FaceButton
	
	Globals.triangles_button = %TrianglesButton
	Globals.wireframe_button = %WireframeButton
	Globals.solid_button = %SolidButton
	Globals.textured_button = %TexturedButton
	
	Globals.zoom_button = %ZoomButton
	Globals.drag_button = %DragButton
	
	call_deferred("set_gizmo_positions")
	%OrbitGizmo.rotated.connect(%"3DScene".apply_rotation)
	%OrbitGizmo.button_clicked.connect(%"3DScene".align_camera)
	%"3DScene".camera_rotated.connect(update_orbit_gizmo)
	
	get_tree().set_auto_accept_quit(false)
	var settings = Settings.new()
	Globals.settings = settings.load_data()
	Globals.main = self
	
	configure_menu()
	call_deferred("test_obj")


func test_obj():
	_on_file_dialog_file_selected("res://assets/cylinder.obj")


func _process(delta: float) -> void:
	if update_timer > 0:
		update_timer -= delta
		if update_timer <= 0:
			set_gizmo_positions()


func _on_h_split_dragged(_offset: int) -> void:
	# This is needed otherwise there is some stutter in the repositioning of items
	call_deferred("set_gizmo_positions")


func set_gizmo_positions():
	%Gizmos.position.x = %SubViewportContainer.size.x - %OrbitGizmo.LARGE_RADIUS * 2


func _on_h_split_resized() -> void:
	update_timer = 0.1


func update_orbit_gizmo(basis: Basis):
	%OrbitGizmo.update(basis)


func set_title():
	var _title = ProjectSettings.get_setting("application/config/name")
	if OS.is_debug_build():
		_title += " (DEBUG)"


func configure_menu():
	var import_menu = PopupMenu.new()
	import_menu.add_item("Mesh")
	import_menu.add_item("SVG")
	var export_menu = PopupMenu.new()
	export_menu.add_item("OBJ (Wavefront)")
	#import_menu.title = "Import"
	file_menu.add_item("New", NEW, KEY_MASK_CTRL | KEY_N)
	file_menu.add_item("Open", OPEN, KEY_MASK_CTRL | KEY_O)
	file_menu.add_separator()
	file_menu.add_item("Save", SAVE, KEY_MASK_CTRL | KEY_S)
	file_menu.add_item("Save As...", SAVE_AS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	file_menu.add_separator()
	file_menu.add_submenu_node_item("Import", import_menu)
	file_menu.add_submenu_node_item("Export", export_menu)
	file_menu.add_separator()
	file_menu.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	file_menu.id_pressed.connect(_on_FileMenu_id_pressed)
	
	add_menu.add_item("Box")
	add_menu.add_item("Cylinder")
	add_menu.add_item("Sphere")
	add_menu.id_pressed.connect(_on_AddMenu_id_pressed)

	help_menu.add_item("About", ABOUT)
	help_menu.add_separator()
	help_menu.add_item("Licences", LICENCES)
	help_menu.id_pressed.connect(_on_HelpMenu_id_pressed)


func _on_FileMenu_id_pressed(id):
	menu_action = id
	match id:
		NEW:
			pass
		OPEN:
			menu_action = OPEN
			do_action()
		SAVE:
			menu_action = SAVE
			do_action()
		SAVE_AS:
			menu_action = SAVE
			Globals.settings.current_file = ""
			do_action()
		QUIT:
			save_and_quit()

func _on_AddMenu_id_pressed(id):
	add_selection.emit(id)


func _on_HelpMenu_id_pressed(id):
	match id:
		ABOUT:
			find_child("About").popup_centered()
		LICENCES:
			find_child("Licences").popup_centered()


func do_action():
	match menu_action:
		OPEN:
			file_dialog.current_dir = Globals.settings.last_dir
			file_dialog.current_file = Globals.settings.current_file
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.popup_centered()
		SAVE:
			if Globals.settings.last_dir == "" or Globals.settings.current_file == "":
				file_dialog.current_dir = Globals.settings.last_dir
				file_dialog.current_file = ""
				file_dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
				file_dialog.popup_centered()
			else:
				alert.show_message("Error saving file")


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_Q and event.ctrl_pressed:
			save_and_quit()

# Handle shutdown of App
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_and_quit()


func save_and_quit():
	Globals.settings.save_data()
	get_tree().quit()


func _on_file_dialog_file_selected(path: String) -> void:
	match menu_action:
		OPEN:
			var file = FileAccess.open(path, FileAccess.READ)
			var txt = file.get_as_text(true)
			load_obj_file.emit(txt)
		SAVE:
			var file = FileAccess.open(path, FileAccess.WRITE)
			save_obj_file.emit(file)
	Globals.settings.last_dir = file_dialog.current_dir
	Globals.settings.current_file = file_dialog.current_file
	
