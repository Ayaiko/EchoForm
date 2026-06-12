extends CharacterBody2D
class_name Monster

# ─── Stats ───────────────────────────────────────────────
@export var monster_name: String = "Unknown"
@export var max_hp: float = 40.0
@export var move_speed: float = 60.0
@export var damage: float = 10.0
@export var attack_range: float = 20.0
@export var detection_range: float = 150.0
@export var gene_attraction_range: float = 220.0  # longer range if player has matching gene

# ─── Gene this monster carries ───────────────────────────
@export var carried_gene: Gene = null
@export var monster_type: String = ""   # e.g. "predator", "fire", "aquatic"

# ─── Prey — monster types this monster will hunt ─────────
@export var hunts_monster_types: Array[String] = []
@export var hunts_gene_types: Array[String] = []  # attacks player if they carry this gene

# ─── State machine ───────────────────────────────────────
enum State { IDLE, WANDER, CHASE_PLAYER, CHASE_MONSTER, ATTACK, DEAD }
var state: State = State.IDLE

var hp: float
var target: Node2D = null
var _attack_cooldown: float = 0.0
var _wander_timer: float = 0.0
var _wander_direction: Vector2 = Vector2.ZERO

# ─── Signals ─────────────────────────────────────────────
signal monster_died(monster)
signal gene_available(gene, position)

func _ready() -> void:
	hp = max_hp
	_wander_timer = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_cooldown -= delta
	_decide_state()
	_execute_state(delta)
	move_and_slide()

# ─── AI Decision ─────────────────────────────────────────
func _decide_state() -> void:
	var player = _find_player()
	var nearest_monster = _find_prey_monster()

	# Gene attraction — player carrying a hunted gene pulls from further away
	if player and _player_has_hunted_gene(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= gene_attraction_range:
			target = player
			state = State.CHASE_PLAYER
			return

	# Normal player detection
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= attack_range:
			target = player
			state = State.ATTACK
			return
		if dist <= detection_range:
			target = player
			state = State.CHASE_PLAYER
			return

	# Hunt other monsters
	if nearest_monster:
		target = nearest_monster
		state = State.CHASE_MONSTER
		return

	# Nothing nearby — wander
	if state != State.WANDER:
		state = State.WANDER

func _execute_state(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WANDER:
			_do_wander(delta)
		State.CHASE_PLAYER, State.CHASE_MONSTER:
			_do_chase()
		State.ATTACK:
			_do_attack()

# ─── Behaviours ──────────────────────────────────────────
func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		_wander_timer = randf_range(1.5, 3.5)
	velocity = _wander_direction * (move_speed * 0.5)

func _do_chase() -> void:
	if not target:
		state = State.IDLE
		return
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed

	if global_position.distance_to(target.global_position) <= attack_range:
		state = State.ATTACK

func _do_attack() -> void:
	velocity = Vector2.ZERO
	if not target or global_position.distance_to(target.global_position) > attack_range:
		state = State.IDLE
		return
	if _attack_cooldown <= 0.0:
		_deal_damage()
		_attack_cooldown = 1.2

func _deal_damage() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

# ─── Helpers ─────────────────────────────────────────────
func _find_player() -> Node2D:
	# Looks for node in group "player"
	var players = get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null

func _find_prey_monster() -> Node2D:
	if hunts_monster_types.is_empty():
		return null
	var monsters = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if m == self:
			continue
		if m.monster_type in hunts_monster_types:
			if global_position.distance_to(m.global_position) <= detection_range:
				return m
	return null

func _player_has_hunted_gene(player: Node2D) -> bool:
	if hunts_gene_types.is_empty():
		return false
	if not player.has_method("get_genes"):
		return false
	for gene in player.get_genes():
		if gene.attracts_monster_type in hunts_gene_types:
			return true
	return false

# ─── Damage & Death ──────────────────────────────────────
func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	if hp <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	emit_signal("monster_died", self)
	if carried_gene:
		emit_signal("gene_available", carried_gene, global_position)
	queue_free()
