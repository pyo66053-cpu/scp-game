extends CharacterBody3D

@export var speed = 4.5
@export var sensitivity = 0.004
@onready var head = $Head
@onready var ray = $Head/RayCast3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event):
	# Поворот камеры пальцем по правой части экрана
	if event is InputEventScreenDrag and event.position.x > get_viewport().size.x * 0.4:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

# Вызовите эту функцию при нажатии на сенсорную кнопку "Взаимодействовать"
func interact():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.has_method("use"):
			collider.use()
