extends CharacterBody3D
class_name Player

var is_talking = false

@onready var player_input: PlayerInput = $Components/PlayerInput
@onready var player_locomotion: PlayerLocomotion = $Components/PlayerLocomotion
@onready var anim_player: AnimationHandler = $Components/AnimationHandler
@onready var player_combat: PlayerCombat = $Components/PlayerCombat

@export_group("Movement")
@export var move_speed = 5.0
@export var run_speed = 8.0
@export var acceleration = 18.0
@export var decceleration = 25.0

func _ready() -> void:
	player_locomotion.start(self)
	player_combat.start(self)
	
	
	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)
	
	
	Dialogic.start("pak_rt_intro")

func _physics_process(delta: float) -> void:
	
	if is_talking:
		
		velocity.x = move_toward(velocity.x, 0, decceleration * delta)
		velocity.z = move_toward(velocity.z, 0, decceleration * delta)
		move_and_slide()
		return 
	
	player_locomotion.move(delta)
	player_combat.input_check()
	move_and_slide()

func _on_dialogue_started():
	is_talking = true
	
func _on_dialogue_ended():
	is_talking = false
