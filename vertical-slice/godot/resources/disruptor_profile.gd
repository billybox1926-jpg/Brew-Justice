extends Resource
class_name DisruptorProfile

## Narrative + mechanical identity for a Disruptor variant.
## Used by `Disruptor` to shape pulse timing/amplitude and surfaced
## in UI/lore as the antagonist's "signature."

@export var id: String
@export var display_name: String
@export var description: String
@export var chaos_style: String = "pulse"  # pulse, drift, burst, wave
@export var base_chaos_rate: float = 0.5
@export var chaos_variance: float = 0.2
@export var color: Color = Color(1.0, 0.5, 0.2)
@export var icon: Texture2D
