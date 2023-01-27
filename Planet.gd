extends RigidBody2D


const LINE_TIMER: float = 0.05 #больше 0.05 не очень красивая траетория становится? или нет
const MAX_NUM_OF_POINTS = 1500

var NUM_OF_POINTS = 1500


var other_planets
var count: float = 0
var l2d: AntialiasedLine2D
var calc_period = false
var turned = false
var time_start = 0
var cur_line_timer: float = LINE_TIMER
var points_in_period = 0


func _ready():
	randomize()
	angular_velocity = rand_range(-1, 1)
	other_planets = get_tree().get_nodes_in_group("Planet")
	other_planets.erase(self)
	l2d = AntialiasedLine2D.new()
	l2d.width = 5
	l2d.gradient = Gradient.new()
	l2d.gradient.set_color(0, Color(0, 0, 0, 0))
	l2d.gradient.set_color(1, Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 1))
	l2d.add_point(global_position)
	get_parent().call_deferred("add_child", l2d)
	time_start = Time.get_ticks_msec()


func check_period():
	if calc_period and not turned:
		if linear_velocity.x >= 0 or linear_velocity.y >= 0:
			turned = true
	if linear_velocity.x < 0 and linear_velocity.y < 0:
		if turned:
			NUM_OF_POINTS = min(points_in_period * 1.5, MAX_NUM_OF_POINTS)
			points_in_period = 0
			turned = false
		else:
			calc_period = true


func calc_cur_line_timer(vel: float):
	if vel > 150:
		return LINE_TIMER / 2
	elif vel > 90:
		return LINE_TIMER
	else:
		return LINE_TIMER * 2


func _process(delta):
	count += delta
	if count > cur_line_timer:
		count -= cur_line_timer
		points_in_period += 1
		check_period()
		cur_line_timer = calc_cur_line_timer(linear_velocity.length())
		l2d.add_point(global_position)
		if l2d.points.size() > NUM_OF_POINTS: #2 раза, чтобы хвост плавно догонял
			l2d.remove_point(0)
		if l2d.points.size() > NUM_OF_POINTS:
			l2d.remove_point(0)


func _physics_process(_delta):
	applied_force = Vector2.ZERO
	var pl_global_position: Vector2
	for pl in other_planets:
		pl_global_position = pl.global_position
		add_central_force(global_position.direction_to(pl_global_position)*
			mass*pl.mass/global_position.distance_squared_to(pl_global_position)*0.6) #*0.66725)
