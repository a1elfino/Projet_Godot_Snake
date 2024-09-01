extends Node

@export var snake_scene: PackedScene

# Game variables
var score: int
var game_started: bool = false
var lives: int = 3  # Add a variable for lives

# Grid variables
var cells: int = 20
var cell_size: int = 50

# Mouse variables
var food_pos: Vector2
var regen_food: bool = true

# Snake variables
var old_data: Array = []
var snake_data: Array = []
var snake: Array = []

# Movement variables
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction: Vector2
var can_move: bool

# Difficulty settings
var difficulty: String = "Easy"
var move_timer_intervals = {
	"Easy": 0.5,
	"Medium": 0.2,
	"Hard": 0.09
}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_difficulty("Easy")
	new_game()

func set_difficulty(selected_difficulty: String):
	difficulty = selected_difficulty
	$MoveTimer.wait_time = move_timer_intervals[difficulty]

func new_game():
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free")
	$GameOverMenu.hide()
	score = 0
	lives = 3  # Reset lives at the start of a new game
	update_lives_label()
	$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	move_direction = up
	can_move = true
	generate_snake()
	move_food()
	
func update_lives_label():
	$Hud.get_node("LivesLabel").text = "LIVES: " + str(lives)
	
func generate_snake():
	old_data.clear()
	snake_data.clear()
	snake.clear()
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))

func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

func _process(delta):
	move_snake()

func move_snake():
	if can_move:
		# Update movement 
		if Input.is_action_just_pressed("move_down") and move_direction != up:
			move_direction = down
			can_move = false
			if not game_started:
				start_game()
		elif Input.is_action_just_pressed("move_up") and move_direction != down:
			move_direction = up
			can_move = false
			if not game_started:
				start_game()
		elif Input.is_action_just_pressed("move_left") and move_direction != right:
			move_direction = left
			can_move = false
			if not game_started:
				start_game()
		elif Input.is_action_just_pressed("move_right") and move_direction != left:
			move_direction = right
			can_move = false
			if not game_started:
				start_game()

func start_game():
	game_started = true
	$MoveTimer.start()

func _on_move_timer_timeout():
	can_move = true
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
	check_out_of_bounds()
	check_self_eaten()
	check_food_eaten()

func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x > cells - 1 or snake_data[0].y < 0 or snake_data[0].y > cells - 1:
		#end_game()
		lose_life()

func check_self_eaten():
	for i in range(1, len(snake_data)):
		if i < snake_data.size() and snake_data[0] == snake_data[i]:
			lose_life()


func check_food_eaten():
	# If snake eats the mouse, add a segment and move the mouse
	if snake_data[0] == food_pos:
		score += 1
		$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
		add_segment(old_data[-1])
		move_food()

func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Mouse.position = (food_pos * cell_size) + Vector2(0, cell_size)
	regen_food = true


func lose_life():
	lives -= 1
	update_lives_label()
	if lives > 0:
		reset_snake()  
		move_food()
	else:
		end_game()

func reset_snake_position():
	move_direction = up
	var snake_length = snake_data.size()
	var new_start_pos = start_pos - Vector2(0, snake_length - 1)
	
	for i in range(snake_length):
		var pos = new_start_pos + Vector2(0, i)
		snake_data[i] = pos
		snake[i].position = (pos * cell_size) + Vector2(0, cell_size)
	
	can_move = true


func await_user_input_to_resume():
	$MoveTimer.stop()
	can_move = false

	# Wait for user input to resume the game
	while true:
		if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
			can_move = true
			$MoveTimer.start()
			break
		await get_tree().process_frame
		
		
		
func _resume_game_after_delay():
	$MoveTimer.stop()
	can_move = false
	await get_tree().create_timer(1.0).timeout  # Wait for 2 seconds
	can_move = true
	$MoveTimer.start()
		
		# Réinitialiser le serpent à sa taille d'origine et supprimer tous les segments actuels
func reset_snake():
	get_tree().call_group("segments", "queue_free")  # Supprimer tous les segments du serpent actuel
	generate_snake()  # Regénérer le serpent à sa taille d'origine
	
	
func end_game():
	$GameOverMenu.show()
	$MoveTimer.stop()
	game_started = false
	get_tree().paused = true

func _on_game_over_menu_restart():
	$start_menu.show()
	new_game()

func _on_start_menu_restart():
	new_game()
	$start_menu.hide()


func _on_button_home_pressed():
	$start_menu.show()
	new_game()
	
