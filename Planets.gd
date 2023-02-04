extends Node2D

const RND_GEN_ASTEROIDS_X = 1000
const RND_GEN_ASTEROIDS_Y = 600
const RND_GEN_ASTEROIDS_SOL_DIST = 400
const RND_GEN_ASTEROIDS_MIN_SPEED = 30
const RND_GEN_ASTEROIDS_MAX_SPEED = 50
const RND_GEN_ASTEROIDS_ANGLE = .5
const RND_GEN_ASTEROIDS_MIN_MASS = .01
const RND_GEN_ASTEROIDS_MAX_MASS = 1
const CAM_ZOOM_SPEED = 0.1
const CAM_MOVE_SPEED = 600
const INFO_TIMER = .1

const USER_DIR_PATH = "user://"
const SAVE_FILE_EXT = ".save"


onready var PLANET = preload("res://Planet.tscn")

onready var sol_camera = $Camera2D
onready	var planets_parent = $Planets

onready var file_list: Control = $UI/VBoxContainer/HBoxContainer/FileLIst
onready var file_item_list: ItemList = $UI/VBoxContainer/HBoxContainer/FileLIst/VBoxContainer/ItemList

onready var file_name_edit: Control = $UI/VBoxContainer/HBoxContainer/FileNameEdit
onready var file_name_line_edit: LineEdit = $UI/VBoxContainer/HBoxContainer/FileNameEdit/VBoxContainer/LineEdit

onready var edit_planet_menu: Control = $UI/EditPlanetMenu
onready var b_new: Button = $UI/EditPlanetMenu/VBoxContainer/BNew
onready var b_edit: Button = $UI/EditPlanetMenu/VBoxContainer/BEdit
onready var b_delete: Button = $UI/EditPlanetMenu/VBoxContainer/BDelete

onready var buttons: HBoxContainer = $UI/VBoxContainer/HBoxContainer/Buttons

onready var planet_info: Control = $UI/VBoxContainer/HBoxContainer/PlanetInfo
onready var info_img = $UI/VBoxContainer/HBoxContainer/PlanetInfo/HBoxContainer/PlanetIMG
onready var info_name = $UI/VBoxContainer/HBoxContainer/PlanetInfo/HBoxContainer/VBoxContainer/PlanetName
onready var info_speed = $UI/VBoxContainer/HBoxContainer/PlanetInfo/HBoxContainer/VBoxContainer2/PlanetSpeed
onready var info_position = $UI/VBoxContainer/HBoxContainer/PlanetInfo/HBoxContainer/VBoxContainer2/PlanetPosition
onready var info_mass = $UI/VBoxContainer/HBoxContainer/PlanetInfo/HBoxContainer/VBoxContainer/PlanetMass

var planets = []
var selected_planet = null
var cam_move: Vector2 = Vector2.ZERO
var lm_pressed = false
var paused = false
var info_timer: float = 0
var dialog_on_screen: bool = false
var edit_dialog_on_screen: bool = false


func _ready():
	randomize()
	planets = get_tree().get_nodes_in_group("Planet")
	generate_asteroids(5)
	sol_camera.global_position = calc_mass_center()
	sol_camera.smoothing_enabled = true
	OS.min_window_size = Vector2(500, 400)


func generate_asteroids(num: int):
	var coord: Vector2
	var vel: Vector2
	for _i in num:
		coord = Vector2(rand_range(-RND_GEN_ASTEROIDS_X, RND_GEN_ASTEROIDS_X), 
					rand_range(-RND_GEN_ASTEROIDS_Y, RND_GEN_ASTEROIDS_Y))
		while coord.distance_to(Vector2.ZERO) < RND_GEN_ASTEROIDS_SOL_DIST:
			coord = Vector2(rand_range(-RND_GEN_ASTEROIDS_X, RND_GEN_ASTEROIDS_X), 
						rand_range(-RND_GEN_ASTEROIDS_Y, RND_GEN_ASTEROIDS_Y))
		vel = Vector2(rand_range(RND_GEN_ASTEROIDS_MIN_SPEED, RND_GEN_ASTEROIDS_MAX_SPEED), 0).rotated(
			coord.angle_to_point(Vector2.ZERO) - rand_range(PI/2 - RND_GEN_ASTEROIDS_ANGLE, PI/2 + RND_GEN_ASTEROIDS_ANGLE))
		add_planet(coord, vel, rand_range(RND_GEN_ASTEROIDS_MIN_MASS, RND_GEN_ASTEROIDS_MAX_MASS))


func add_planet(coord: Vector2, lin_vel: Vector2 = Vector2.ZERO, m: float = 1):
	var p = PLANET.instance()
	p.transform.origin = coord
	p.linear_velocity = lin_vel
	p.mass = m
	p.get_node("Sprite").scale *= .3
	planets_parent.add_child(p)
	planets.append(p)
	sort_planets()
	return p


func _process(delta):
	info_timer += delta
	if info_timer >= INFO_TIMER:
		info_timer -= INFO_TIMER
		update_info(false)
	if not edit_dialog_on_screen:
		cam_move = Vector2.ZERO
		if Input.is_action_pressed("ui_left"):
			cam_move.x -= CAM_MOVE_SPEED * delta
		if Input.is_action_pressed("ui_right"):
			cam_move.x += CAM_MOVE_SPEED * delta
		if Input.is_action_pressed("ui_up"):
			cam_move.y -= CAM_MOVE_SPEED * delta
		if Input.is_action_pressed("ui_down"):
			cam_move.y += CAM_MOVE_SPEED * delta
		
		if cam_move.length() > 0:
			change_cam_parent(self)
			sol_camera.global_position += cam_move


func update_info(all_info: bool):
	if selected_planet:
		if all_info:
			planet_info.show()
			info_img.texture = selected_planet.get_node("Sprite").texture
			info_name.text = "Name: " + selected_planet.name
			info_mass.text = "Mass: " + str(stepify(selected_planet.mass, 0.01))
		info_speed.text = "Speed: " + str(stepify(selected_planet.linear_velocity.length(), 0.1))
		var g_p: Vector2 = selected_planet.global_position
		info_position.text = "Position: (" + str(stepify(g_p.x, 0.1)) + ", " + str(stepify(g_p.y, 0.1)) + ")"


func calc_mass_center() -> Vector2:
	var sum1: Vector2 = Vector2.ZERO
	var sum2: float = 0
	for p in planets:
		sum1 += p.global_position * p.mass
		sum2 += p.mass
	return sum1 / sum2


func sort_by_mass(a, b):
	if a.mass > b.mass:
		return true
	return false


func sort_planets():
	planets.sort_custom(self, "sort_by_mass")
#	print(planets)
	for p in planets:
		p.set_other_planets(planets)


func delete_planet(planet):
#	if planet == planets[0]: return
	planets.erase(planet)
	if sol_camera.get_parent() == planet:
		change_cam_parent(self)
		sol_camera.global_position = calc_mass_center()
	planet.l2d.queue_free()
	planet.queue_free()
	sort_planets()


func change_cam_parent(new_parent):
	if new_parent == null: return
	var c_p = sol_camera.get_parent()
	if c_p != new_parent:
		c_p.remove_child(sol_camera)
		if new_parent == self:
			sol_camera.position = c_p.position
			selected_planet = null
			planet_info.hide()
		else:
			sol_camera.position = Vector2.ZERO
			selected_planet = new_parent
		new_parent.add_child(sol_camera)
		update_info(true)


func get_planet_XY(xy: Vector2):
	for p in planets:
		if xy.distance_to(p.global_position) < 20:
			return p
	return null


func _unhandled_input(event: InputEvent) -> void:
	# scale change wheel control
	if event is InputEventMouseButton and not edit_dialog_on_screen:
		match event.button_index:
			BUTTON_WHEEL_DOWN:
				if !event.pressed:
					return
				sol_camera.zoom += Vector2.ONE * CAM_ZOOM_SPEED
			BUTTON_WHEEL_UP:
				if !event.pressed:
					return
				var new_zoom = max(sol_camera.zoom.x - CAM_ZOOM_SPEED, 0.5)
				sol_camera.zoom = Vector2.ONE * new_zoom
			BUTTON_LEFT:
				if event.pressed:
					lm_pressed = true
					sol_camera.smoothing_enabled = false
				else:
					change_cam_parent(get_planet_XY(get_global_mouse_position()))
					lm_pressed = false
					sol_camera.smoothing_enabled = true
			BUTTON_RIGHT:
				if event.pressed and paused:
					click_position = get_global_mouse_position()
					var pl = get_planet_XY(click_position)
					if pl: change_cam_parent(pl)
					show_edit_planet_menu(pl, get_viewport().get_mouse_position())
	elif event is InputEventMouseMotion and lm_pressed:
		change_cam_parent(self)
		sol_camera.global_position -= event.relative * sol_camera.zoom.x
	elif event is InputEventKey and not dialog_on_screen and not edit_dialog_on_screen:
		if event.is_action_released("ui_select"):
			change_pause()
		elif event.is_action_released("ui_home"):
			change_cam_parent(self)
			sol_camera.global_position = calc_mass_center()


func change_pause():
	print("change_pause")
	get_tree().paused = not paused
	paused = not paused
	buttons.visible = paused


func _on_Load_pressed():
	print("_on_Load_pressed")
	show_file_list()


func _on_Save_pressed():
	print("_on_Save_pressed")
	file_name_line_edit.text = ""
	show_hide_file_name_edit(true)


func show_edit_planet_menu(pl, coord):
	if pl == null:
		b_new.show()
		b_edit.hide()
		b_delete.hide()
		edit_planet_menu.rect_position = coord + Vector2(10, 0)
		edit_planet_menu.show()
		edit_dialog_on_screen = true
	else:
		b_new.hide()
		b_edit.show()
		b_delete.show()
		edit_planet_menu.rect_position = get_viewport_rect().size / 2 + Vector2(10, 0)
		edit_planet_menu.show()
		edit_dialog_on_screen = true


func hide_edit_planet_menu():
	edit_planet_menu.hide()
	edit_dialog_on_screen = false


func _on_BCancel_pressed() -> void:
	hide_edit_planet_menu()


func _on_BDelete_pressed() -> void:
	delete_planet(selected_planet)
	hide_edit_planet_menu()

var click_position: Vector2 = Vector2.ZERO
func _on_BNew_pressed() -> void:
#	print(edit_planet_menu.get_canvas_transform())
#	print(edit_planet_menu.get_global_rect())
#	print(edit_planet_menu.get_global_transform())
#	print(edit_planet_menu.get_global_transform_with_canvas())
#	print(edit_planet_menu.get_rect())
#	print(edit_planet_menu.get_transform())
#	print(edit_planet_menu.get_viewport_transform())
#	print(edit_planet_menu.rect_global_position)
#	print(sol_camera.global_position)
#	change_cam_parent(add_planet($UI.transform * edit_planet_menu.rect_global_position))
	change_cam_parent(add_planet(click_position))
	hide_edit_planet_menu()
#	show_edit_dialog()


func show_hide_file_list(_show):
	if _show:
		buttons.hide()
		file_list.show()
	else:
		buttons.show()
		file_list.hide()
	dialog_on_screen = _show


func show_hide_file_name_edit(_show):
	if _show:
		buttons.hide()
		file_name_edit.show()
	else:
		buttons.show()
		file_name_edit.hide()
	dialog_on_screen = _show


func _on_Cancel_pressed() -> void:
	print("_on_Cancel_pressed")
	show_hide_file_list(false)


func _on_Save_Cancel_pressed() -> void:
	print("_on_Save_Cancel_pressed")
	show_hide_file_name_edit(false)


func _on_Select_pressed() -> void:
	print("_on_Select_pressed")
	if file_item_list.is_anything_selected():
		load_orbits(file_item_list.get_item_text(file_item_list.get_selected_items()[0]))
		show_hide_file_list(false)


func _on_Save_Select_pressed() -> void:
	print("_on_Save_Select_pressed")
	if file_name_line_edit.text.is_valid_filename():
		save_orbits(file_name_line_edit.text)
#		load_orbits(file_item_list.get_item_text(file_item_list.get_selected_items()[0]))
		show_hide_file_name_edit(false)


func save_orbits(file_name):
	var save_file = File.new()
	save_file.open(USER_DIR_PATH + file_name + SAVE_FILE_EXT, File.WRITE)
	for p in planets:
		# Check the node is an instanced scene so it can be instanced again during load.
		if p.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % p.name)
			continue
		# Check the node has a save function.
		if !p.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % p.name)
			continue
		# Call the node's save function.
		var node_data = p.save()
		# Store the save dictionary as a new line in the save file.
		save_file.store_line(to_json(node_data))
	save_file.close()


func get_save_files(path):
	var files = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(SAVE_FILE_EXT):
				files.append(file)
			file = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")
	return files


func show_file_list():
	var save_files = get_save_files(USER_DIR_PATH)
	file_item_list.clear()
	show_hide_file_list(true)
	for f in save_files:
		file_item_list.add_item(f)


func load_orbits(selected_file):
	print(selected_file)
	var load_file = File.new()
	if not load_file.file_exists(USER_DIR_PATH + selected_file):
		print("Error! We don't have a save to load.")
		return
	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	change_cam_parent(self)
	for p in planets:
		planets_parent.remove_child(p)
		planets_parent.remove_child(p.l2d)
		p.l2d.queue_free()
		p.queue_free()
	planets.clear()
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	load_file.open(USER_DIR_PATH + selected_file, File.READ)
	while load_file.get_position() < load_file.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(load_file.get_line())
		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.set_name(node_data["name"])
		new_object.position = Vector2(node_data["position_x"], node_data["position_y"])
		new_object.linear_velocity = Vector2(node_data["linear_velocity_x"], node_data["linear_velocity_y"])
		new_object.mass = node_data["mass"]
		var s: Sprite = new_object.get_node("Sprite")
		s.texture = load(node_data["Sprite_texture"])
		s.scale = Vector2(node_data["Sprite_scale_x"], node_data["Sprite_scale_y"])
		planets.append(new_object)
	load_file.close()
	sort_planets()
	sol_camera.global_position = calc_mass_center()
