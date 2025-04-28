# GameManager.gd
# Autoload Singleton
# Manages global game state, time progression, and central event coordination.
extends Node

# Signal emitted when time advances by one week.
# Connect systems like GardeningSystem, NPCSystem, CompostBin timers to this.
signal time_advanced(week: int, season: String)

# Game time properties
var current_week: int = 1
var current_season: String = "Spring" # Example starting season
const WEEKS_PER_SEASON: int = 12 # Example value, adjust as needed per GDD

func _ready() -> void:
	print("GameManager ready.")

# Called by the Monastery Door interaction (after confirmation)
func advance_time() -> void:
	current_week += 1
	# Basic season change logic (example)
	if current_week > WEEKS_PER_SEASON:
		current_week = 1
		match current_season:
			"Spring":
				current_season = "Summer"
			"Summer":
				current_season = "Autumn"
			"Autumn":
				current_season = "Winter"
			"Winter":
				# Assuming game loops back to Spring for the prototype or next year
				current_season = "Spring" 
				print("A new year begins!") # Placeholder message

	print("Advancing time to: ", current_season, ", Week ", current_week)
	# Emit the signal to notify other systems
	time_advanced.emit(current_week, current_season)

	# Placeholder for checking quest deadlines (implement later)
	_check_quest_deadlines()

func _check_quest_deadlines() -> void:
	# TODO: Query active quests from QuestManager (once it exists)
	# TODO: Compare quest.deadline_week with current_week
	# TODO: If deadline is near (e.g., current_week == quest.deadline_week - 1),
	#       call UIManager.show_popup("Reminder: Quest deadline next week!")
	pass # Placeholder
