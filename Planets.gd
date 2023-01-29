extends Node2D

const RND_GEN_ASTEROIDS_X = 700
const RND_GEN_ASTEROIDS_Y = 400
const RND_GEN_ASTEROIDS_SOL_DIST = 300
const RND_GEN_ASTEROIDS_MIN_SPEED = 30
const RND_GEN_ASTEROIDS_MAX_SPEED = 60
const RND_GEN_ASTEROIDS_ANGLE = 1
const RND_GEN_ASTEROIDS_MIN_MASS = .01
const RND_GEN_ASTEROIDS_MAX_MASS = .01
const CAM_ZOOM_SPEED = 0.1
const CAM_MOVE_SPEED = 600


onready var PLANET = preload("res://Planet.tscn")
onready var sol_camera = $Planets/Sol/Camera2D
onready var main_star = $Planets/Sol #надо назначать самую массивную
onready var ui_buttons_load = $UI/Buttons/Load
onready var ui_buttons_save = $UI/Buttons/Save
onready	var planets_parent = $Planets

var planets = []
var cam_move: Vector2 = Vector2.ZERO
var rm_pressed = false
var paused = false


func _ready():
	randomize()
	generate_asteroids(5)
	planets = get_tree().get_nodes_in_group("Planet")
	for p in planets:
		p.set_other_planets(planets)


func generate_asteroids(num: int):
	var p
	var v: Vector2
	for _i in num:
		p = PLANET.instance()
		v = Vector2(rand_range(-RND_GEN_ASTEROIDS_X, RND_GEN_ASTEROIDS_X), 
					rand_range(-RND_GEN_ASTEROIDS_Y, RND_GEN_ASTEROIDS_Y))
		while v.distance_to(Vector2.ZERO) < RND_GEN_ASTEROIDS_SOL_DIST:
			v = Vector2(rand_range(-RND_GEN_ASTEROIDS_X, RND_GEN_ASTEROIDS_X), 
						rand_range(-RND_GEN_ASTEROIDS_Y, RND_GEN_ASTEROIDS_Y))
		p.transform.origin = v
		v = Vector2(rand_range(RND_GEN_ASTEROIDS_MIN_SPEED, RND_GEN_ASTEROIDS_MAX_SPEED), 0).rotated(
			v.angle_to_point(Vector2.ZERO) - rand_range(PI/2 - RND_GEN_ASTEROIDS_ANGLE, PI/2 + RND_GEN_ASTEROIDS_ANGLE))
		p.linear_velocity = v
		p.mass = rand_range(RND_GEN_ASTEROIDS_MIN_MASS, RND_GEN_ASTEROIDS_MAX_MASS)
		p.get_node("Sprite").scale *= .3
		planets_parent.add_child(p)


func _process(delta):
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


func change_cam_parent(new_parent):
	if new_parent == null: return
	var c_p = sol_camera.get_parent()
	if c_p != new_parent:
		c_p.remove_child(sol_camera)
		if new_parent == self:
			sol_camera.position = c_p.position
		else:
			sol_camera.position = Vector2.ZERO
		new_parent.add_child(sol_camera)


func get_planet_XY(xy: Vector2):
	for p in planets:
		if xy.distance_to(p.global_position) < 20:
			return p
	return null


func _input(event):
	# scale change wheel control
	if event is InputEventMouseButton:
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
				if !event.pressed:
					change_cam_parent(get_planet_XY(get_global_mouse_position()))
			BUTTON_RIGHT:
				if event.pressed:
					rm_pressed = true
					sol_camera.smoothing_enabled = false
				else:
					rm_pressed = false
					sol_camera.smoothing_enabled = true
	elif event is InputEventMouseMotion and rm_pressed:
		change_cam_parent(self)
		sol_camera.global_position -= event.relative * sol_camera.zoom.x
	elif event is InputEventKey:
		if event.is_action_released("ui_select"):
			change_pause()


func change_pause():
	ui_buttons_load.disabled = paused
	ui_buttons_save.disabled = paused
	get_tree().paused = not paused
	paused = not paused


func _on_Load_pressed():
	load_orbits()


func _on_Save_pressed():
	save_orbits()


func save_orbits():
	var save_file = File.new()
	save_file.open("user://orbits.save", File.WRITE)
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


func load_orbits():
	var load_file = File.new()
	if not load_file.file_exists("user://orbits.save"):
		print("Error! We don't have a save to load.")
		return
	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	for p in planets:
		p.l2d.queue_free()
		p.queue_free()
	planets.clear()
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	load_file.open("user://orbits.save", File.READ)
	while load_file.get_position() < load_file.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(load_file.get_line())
		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.position = Vector2(node_data["position_x"], node_data["position_y"])
		new_object.linear_velocity = Vector2(node_data["linear_velocity_x"], node_data["linear_velocity_y"])
		new_object.mass = node_data["mass"]
		var s: Sprite = new_object.get_node("Sprite")
		s.texture = load(node_data["Sprite_texture"])
		s.scale = Vector2(node_data["Sprite_scale_x"], node_data["Sprite_scale_y"])
		planets.append(new_object)
	for p in planets:
		p.set_other_planets(planets)
	load_file.close()
