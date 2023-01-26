extends RigidBody2D


const LINE_TIMER = 0.03 #больше 0.03 не очень красивая траетория становится? или нет
const MAX_NUM_OF_POINTS = 1000

var NUM_OF_POINTS = 1000


var other_planets
var count = 0
var l2d: Line2D
var calc_period = false
var turned = false
var time_start = 0


func _ready():
	randomize()
	angular_velocity = rand_range(-1, 1)
	other_planets = get_tree().get_nodes_in_group("Planet")
	other_planets.erase(self)
	l2d = Line2D.new()
	l2d.antialiased = true
	l2d.width = 2
	l2d.gradient = Gradient.new()
	l2d.gradient.set_color(0, Color(0, 0, 0, 0))
	l2d.gradient.set_color(1, Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1), 1))
	l2d.add_point(global_position)
	get_parent().call_deferred("add_child", l2d)
	time_start = Time.get_ticks_msec()


func change_num_of_points(t: float):
	NUM_OF_POINTS = min(t/1100.0/LINE_TIMER, MAX_NUM_OF_POINTS) #зависит от fps?


func check_period():
	if calc_period and not turned:
		if linear_velocity.x >= 0 or linear_velocity.y >= 0:
			turned = true
	if linear_velocity.x < 0 and linear_velocity.y < 0:
		if turned:
			var t = Time.get_ticks_msec()
			change_num_of_points(t-time_start)
			time_start = t
			turned = false
		else:
			calc_period = true


func _process(delta):
	count += delta
	if count > LINE_TIMER:
		check_period()
		count -= LINE_TIMER
		l2d.add_point(global_position)
		if l2d.points.size() > NUM_OF_POINTS:
			l2d.remove_point(0)
		if l2d.points.size() > NUM_OF_POINTS:
			l2d.remove_point(0)


func _physics_process(_delta):
	applied_force = Vector2.ZERO
	var pl_global_position: Vector2
	for pl in other_planets:
		pl_global_position = pl.global_position
		add_central_force(global_position.direction_to(pl_global_position)*
			mass*pl.mass/global_position.distance_squared_to(pl_global_position)*100)
