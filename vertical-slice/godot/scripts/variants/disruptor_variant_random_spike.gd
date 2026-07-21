extends DisruptorVariant

## "Random spike" — irregular, sharp static strokes with no clear period.
## Feels like a release valve blowing off steam or a loose connection.
func _init() -> void:
	variant_name = "random_spike"
	intensity = 0.9
	duration = 0.15
	interval = 5.0
	auditory_band = "high"
	lore_fragment = "A sharp static snaps the air every few seconds."

