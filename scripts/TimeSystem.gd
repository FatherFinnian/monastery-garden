# Purpose:
#   • Own in-game calendar (week + season)
#   • Emit a single `week_advanced` signal via EventBus
#   • No direct references to UI, plots, quests, etc.
#
# How to advance time:
#     TimeSystem.advance_week()      # e.g. Door interaction
#
# How to listen:
#     EventBus.week_advanced.connect(_on_week)
#
# ------------------------------------------------------------------

extends Node

# One public signal so tests or tools can connect straight to this
signal week_advanced(new_week: int, new_season: StringName)

# ------------------------------------------------------------------
#  Calendar data
# ------------------------------------------------------------------
var current_week: int = 1
var current_season: StringName = "Spring"

const SEASONS: PackedStringArray = ["Spring", "Summer", "Autumn", "Winter"]
const WEEKS_PER_SEASON: int = 12     # Matches TDD spec
const TOTAL_SEASONS: int = SEASONS.size()

# ------------------------------------------------------------------
#  Engine callbacks
# ------------------------------------------------------------------
func _ready() -> void:
	print("TimeSystem ready – Season %s, Week %d" % [current_season, current_week])

# ------------------------------------------------------------------
#  Public API
# ------------------------------------------------------------------
## Called by the Monastery Door, cheat keys, unit-tests, etc.
func advance_week() -> void:
	current_week += 1
	if current_week > WEEKS_PER_SEASON:
		current_week = 1
		var season_index := SEASONS.find(current_season)
		season_index = (season_index + 1) % TOTAL_SEASONS
		current_season = SEASONS[season_index]

	# Console trace for quick debugging
	print("Week advanced → %s week %d" % [current_season, current_week])

	# 1) Re-emit centrally for decoupled listeners
	EventBus.week_advanced.emit(current_week, current_season)

	# 2) Also emit locally so unit-tests can bypass EventBus if desired
	week_advanced.emit(current_week, current_season)
