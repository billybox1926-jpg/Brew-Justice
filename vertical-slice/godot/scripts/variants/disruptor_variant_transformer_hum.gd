extends DisruptorVariant

## "Distant transformer hum" — a low, constant mechanical drone that
## penetrates the room regardless of the player's focus state.
func _init() -> void:
	variant_name = "transformer_hum"
	intensity = 0.5
	duration = 1.0
	interval = 4.0
	auditory_band = "low"
	lore_fragment = "A distant transformer hums through the wall."

