extends CharacterBody3D
class_name Enemy

signal died(enemy: Enemy)

@export var max_health: float = 20.0
@export var move_speed: float = 3.0
@export var stop_distance: float = 1.0

@export_group("Attack")
@export var damage: float = 10.0
@export var attack_range: float = 1.5        # dipakai deteksi default (jarak angka)
@export var attack_cooldown: float = 1.0
@export var attack_hit_delay: float = 0.3    # jeda dari mulai animasi sampai damage kena
@export var attack_duration: float = 0.5     # total lama state menyerang

var health: float
var target: Node3D
var is_dead: bool = false
var attacking: bool = false

var _cooldown_left: float = 0.0

@onready var sprite: AnimatedSprite3D = $Visual/AnimatedSprite3D

var facing_left: bool = false

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = _find_player(get_tree().current_scene)
	_on_ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if target == null:
		target = _find_player(get_tree().current_scene)

	if not is_on_floor():
		velocity += get_gravity() * delta

	_cooldown_left -= delta

	if attacking:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_move(delta)
		_try_attack()

	move_and_slide()

# ---------- Bisa di-override oleh turunan ----------

func _on_ready() -> void:
	pass

# Cara mengecek target dalam jangkauan. Default: jarak angka.
func _is_target_in_range() -> bool:
	if target == null:
		return false
	return global_position.distance_to(target.global_position) <= attack_range

# Isi serangan. Dipanggil saat hit_delay selesai.
func _perform_attack() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

func _on_death() -> void:
	pass

# ---------- Gerak (default: mengejar target) ----------
func _move(_delta: float) -> void:
	if target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		play_anim("idle")
		return

	# Player sudah dalam jangkauan serang: berhenti (serangan diurus _try_attack)
	if _is_target_in_range():
		velocity.x = 0.0
		velocity.z = 0.0
		_face_target()
		if not attacking:
			play_anim("idle")
		return

	# Di luar jangkauan: kejar
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var dir: Vector3 = to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face_target()
	play_anim("walk")

func _face_target() -> void:
	if target == null:
		return
	var dx: float = target.global_position.x - global_position.x
	if abs(dx) > 0.1:
		sprite.flip_h = dx < 0.0   # kalau terbalik, ganti jadi dx > 0.0
# ---------- Serangan (alur umum) ----------

func _try_attack() -> void:
	if _cooldown_left > 0.0 or not _is_target_in_range():
		return
	_start_attack()

func _start_attack() -> void:
	attacking = true
	_cooldown_left = attack_cooldown
	play_anim("attack")

	await get_tree().create_timer(attack_hit_delay).timeout
	if is_dead:
		return
	if _is_target_in_range():       # kalau player sempat menghindar, gigitan meleset
		_perform_attack()

	await get_tree().create_timer(maxf(attack_duration - attack_hit_delay, 0.0)).timeout
	attacking = false

# ---------- Umum ----------

func play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	health -= amount
	if health <= 0.0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	_on_death()
	died.emit(self)

	if sprite and sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		await sprite.animation_finished
	queue_free()

func _find_player(node: Node) -> Player:
	if node is Player:
		return node
	for child in node.get_children():
		var found: Player = _find_player(child)
		if found:
			return found
	return null
	
# Dipanggil saat arah hadap berubah
func _set_facing(left: bool) -> void:
	if left == facing_left:
		return
	facing_left = left
	sprite.flip_h = left   # kalau sprite terbalik, ganti jadi: sprite.flip_h = not left
	_on_facing_changed(left)

# Bisa di-override turunan (misalnya untuk memindahkan AttackArea)
func _on_facing_changed(_left: bool) -> void:
	pass
