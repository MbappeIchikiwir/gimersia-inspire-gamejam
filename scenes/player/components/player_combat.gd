extends CombatSystem
class_name PlayerCombat

var player: Player
var anim_handler: AnimationHandler
var player_input: PlayerInput

@export_group("Attcks")
@export var melee_attack: AttackData
@export var range_attack: AttackData

func start(owner: Player):
	player = owner
	anim_handler = player.anim_player
	player_input = player.player_input
	
	anim_handler.frame_changed.connect(_on_attack_frame_changed)
	anim_handler.action_finished.connect(finish_attack)

	
func input_check():
	if anim_handler.on_action: return
	if player_input.melee_attack:
		start_attack(melee_attack)

	if player_input.range_attack_hold:
		anim_handler.play_action("range_hold", false)
		
	if player_input.range_attack_release:
		start_attack(range_attack)

func play_attack_animation(animation_name: StringName) -> void:
	anim_handler.play_action(animation_name, true)
	
func _on_attack_frame_changed(frame: int) -> void:
	if not is_attacking or current_attack == null:
		return

	if frame == current_attack.active_start_frame:
		print("Hitbox activated")

	if frame == current_attack.active_end_frame:
		print("Hitbox deactivated")
