extends Resource
class_name DisruptorVariant

## Antagonist behavior and sensory fingerprint for a Disruptor.
## Used by Disruptor to vary chaos emission without hardcoding variants.

enum Type { Constant, Rhythmic, RandomSpike, Pattern }

@export var variant_name: String = ""
@export var intensity: float = 0.8
@export var duration: float = 0.5
@export var interval: float = 2.0
@export var auditory_band: String = "mid"
@export var lore_text: String = ""
