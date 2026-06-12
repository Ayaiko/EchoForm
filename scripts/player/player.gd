extends CharacterBody2D

# ─── Stats ───────────────────────────────────────────────
@export var move_speed: float = 120.0
@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 10.0   # per second
@export var stamina_sprint_cost: float = 20.0  # per second

# ─── State ───────────────────────────────────────────────
var hp: float
var stamina: float
var is_dead: bool = false
var active_genes: Array = []   # holds Gene resources
const MAX_GENES: int = 4

# ─── Signals ─────────────────────────────────────────────
signal hp_changed(new_hp: float, max_hp: float)
signal stamina_changed(new_stamina: float, max_stamina: float)
signal gene_absorbed(gene)
signal gene_sacrificed(gene)
signal player_died

# ─── Internal ────────────────────────────────────────────
var _is_sprinting: bool = false

func _ready() -> void:
	hp = max_hp
	stamina = max_stamina

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_movement(delta)
	_handle_stamina(delta)
	move_and_slide()

# ─── Movement ────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	_is_sprinting = Input.is_action_pressed("sprint") and stamina > 0.0
	var speed = move_speed * (1.5 if _is_sprinting else 1.0)
	velocity = direction * speed

# ─── Stamina ─────────────────────────────────────────────
func _handle_stamina(delta: float) -> void:
	if _is_sprinting and velocity.length() > 0:
		stamina -= stamina_sprint_cost * delta
		stamina = max(stamina, 0.0)
	else:
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)
	emit_signal("stamina_changed", stamina, max_stamina)

# ─── Damage ──────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if is_dead:
		return
	hp -= amount
	hp = max(hp, 0.0)
	emit_signal("hp_changed", hp, max_hp)
	if hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	emit_signal("player_died")

# ─── Gene System ─────────────────────────────────────────
func absorb_gene(gene, hp_cost: float = 15.0, stamina_cost: float = 25.0) -> bool:
	# Pay the price first
	if hp <= hp_cost:
		return false   # too weak to absorb
	if stamina < stamina_cost:
		return false   # too exhausted

	take_damage(hp_cost)
	stamina -= stamina_cost
	emit_signal("stamina_changed", stamina, max_stamina)

	# If at capacity, must sacrifice one gene first
	if active_genes.size() >= MAX_GENES:
		return false   # caller should prompt sacrifice UI

	active_genes.append(gene)
	emit_signal("gene_absorbed", gene)
	return true

func sacrifice_gene(index: int) -> void:
	if index < 0 or index >= active_genes.size():
		return
	var sacrificed = active_genes[index]
	active_genes.remove_at(index)
	emit_signal("gene_sacrificed", sacrificed)

func get_genes() -> Array:
	return active_genes
