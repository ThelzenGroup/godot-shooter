class_name GameConstants
extends RefCounted

const MAX_WAVE: int = 5
const WORLD_LAYER: int = 1
const PLAYER_LAYER: int = 2
const PROJECTILE_LAYER: int = 4
const ENEMY_LAYER: int = 8
const WORLD_MASK: int = PLAYER_LAYER | ENEMY_LAYER
const PLAYER_MASK: int = WORLD_LAYER | ENEMY_LAYER
const ENEMY_MASK: int = WORLD_LAYER | PLAYER_LAYER | ENEMY_LAYER
const HITSCAN_MASK: int = WORLD_LAYER | ENEMY_LAYER
