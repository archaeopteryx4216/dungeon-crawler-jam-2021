extends Spatial

signal get_fuel(ammount)

export var fuel_per_can = 50

func pickup():
	emit_signal("get_fuel", fuel_per_can)
	queue_free()
