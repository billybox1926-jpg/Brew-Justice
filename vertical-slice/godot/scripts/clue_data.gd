extends Resource
class_name ClueData

enum ClueType { VISUAL, AUDITORY, TACTILE, OLFACTORY }

@export var clue_id: String
@export var clue_name: String
@export var type: ClueType = ClueType.VISUAL
@export var description: String

# Smoothstep band for clarity: presence in [threshold-0.2 .. threshold+0.1] → 0..1
@export var presence_threshold: float = 0.7

# Relationship ids
@export var leads_to: Array[String] = []
@export var contradicts: Array[String] = []
@export var combines_with: Array[String] = []

@export var resolved_text: String = ""
