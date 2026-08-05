extends Node

signal health_changed(value: int, maximum: int)
signal ammo_changed(current: int, reserve: int)
signal score_changed(value: int)
signal wave_changed(value: int, remaining: int, countdown: float)
signal mode_changed(title: String, subtitle: String)
signal player_died
signal player_victory

var health: int = 100
var max_health: int = 100
var ammo: int = 12
var reserve: int = 72
var score: int = 0
var wave: int = 0
var enemies_remaining: int = 0
var dead: bool = false

func reset() -> void:
	health = max_health
	ammo = 12
	reserve = 72
	score = 0
	wave = 0
	enemies_remaining = 0
	dead = false
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, reserve)
	score_changed.emit(score)
	wave_changed.emit(wave, enemies_remaining, 0.0)

func damage(amount: int) -> void:
	if dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		dead = true
		player_died.emit()

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func victory() -> void:
	if not dead:
		player_victory.emit()
