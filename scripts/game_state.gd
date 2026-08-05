extends Node

signal health_changed(value: int, maximum: int)
signal ammo_changed(current: int, reserve: int)
signal score_changed(value: int)
signal wave_changed(value: int, remaining: int)
signal mode_changed(title: String, subtitle: String)

var health: int = 100
var max_health: int = 100
var ammo: int = 12
var reserve: int = 72
var score: int = 0
var wave: int = 0
var enemies_remaining: int = 0

func reset() -> void:
	health = max_health
	ammo = 12
	reserve = 72
	score = 0
	wave = 0
	enemies_remaining = 0
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, reserve)
	score_changed.emit(score)
	wave_changed.emit(wave, enemies_remaining)

func damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
