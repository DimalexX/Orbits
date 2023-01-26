extends Node2D


const CAM_ZOOM_SPEED = 0.1
const CAM_MOVE_SPEED = 600


onready var PLANET = preload("res://Planet.tscn")
onready var sol_camera = $Camera2D
onready var main_star = $Sol

var planets = []
var cam_move: Vector2 = Vector2.ZERO
var rm_pressed = false


func _ready():
	randomize()
	var p
	var v: Vector2
	for _i in 10:
		p = PLANET.instance()
		v = Vector2(rand_range(100, 1500), rand_range(100, 800))
		if v.x > 600 and v.x < 1000 and v.y > 250 and v.y < 650:
			v = v * 2
		p.transform.origin = v
		v = Vector2(rand_range(30, 60), 0).rotated(
			v.angle_to_point(Vector2(800, 450)) - rand_range(PI/2 - 1, PI/2 + 1))
		p.linear_velocity = v
		p.mass = rand_range(.1, 5)
		p.get_node("Sprite").scale *= .1
		add_child(p)
	planets = get_tree().get_nodes_in_group("Planet")


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
