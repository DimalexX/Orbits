extends Node2D

const RND_GEN_ASTEROIDS_X = 700
const RND_GEN_ASTEROIDS_Y = 400
const RND_GEN_ASTEROIDS_SOL_DIST = 200
const RND_GEN_ASTEROIDS_MIN_SPEED = 30
const RND_GEN_ASTEROIDS_MAX_SPEED = 60
const RND_GEN_ASTEROIDS_ANGLE = 1
const RND_GEN_ASTEROIDS_MIN_MASS = .01
const RND_GEN_ASTEROIDS_MAX_MASS = .01
const CAM_ZOOM_SPEED = 0.1
const CAM_MOVE_SPEED = 600


onready var PLANET = preload("res://Planet.tscn")
onready var sol_camera = $Sol/Camera2D
onready var main_star = $Sol

var planets = []
var cam_move: Vector2 = Vector2.ZERO
var rm_pressed = false


func _ready():
	randomize()
	generate_asteroids(3)
	planets = get_tree().get_nodes_in_group("Planet")


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
		add_child(p)


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
