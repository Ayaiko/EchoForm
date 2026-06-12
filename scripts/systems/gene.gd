extends Resource
class_name Gene

# ─── Identity ────────────────────────────────────────────
@export var gene_name: String = "Unknown Gene"
@export var description: String = ""
@export var biome_origin: String = ""   # forest, desert, ocean, lava
@export var is_boss_gene: bool = false

# ─── What the gene does ──────────────────────────────────
enum GeneType { ACTIVE, PASSIVE }
@export var gene_type: GeneType = GeneType.PASSIVE

# Passive stat modifiers (multipliers, e.g. 1.2 = +20%)
@export var hp_modifier: float = 1.0
@export var speed_modifier: float = 1.0
@export var damage_modifier: float = 1.0
@export var stamina_modifier: float = 1.0

# Active ability (if gene_type == ACTIVE)
@export var ability_name: String = ""
@export var ability_damage: float = 0.0
@export var ability_stamina_cost: float = 0.0
@export var ability_cooldown: float = 1.0

# ─── Attraction — which monster types hunt this gene ─────
@export var attracts_monster_type: String = ""  # e.g. "predator", "fire", "aquatic"

# ─── Corruption weight ───────────────────────────────────
# Higher = contributes more to corruption when held
@export var corruption_weight: float = 1.0

# ─── Combine rules ───────────────────────────────────────
# If this gene + target_gene_name are both held → evolves into result_gene_id
@export var combine_with: String = ""
@export var combine_result: String = ""   # resource path or gene id

# ─── Archive ─────────────────────────────────────────────
# Can this gene be etched into the Gene Archive on death?
@export var archivable: bool = true

# ─── Display ─────────────────────────────────────────────
@export var color: Color = Color.WHITE   # used for placeholder sprite tint
