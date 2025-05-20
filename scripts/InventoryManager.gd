# InventoryManager.gd
# Autoload Singleton (formerly ResourceManager in TDD)
# Tracks player inventory (items, seeds, tools), tool durability, watering pot status, and tool repair state.
extends Node

# Signals for UI updates or other systems reacting to inventory changes.
signal inventory_updated # Generic signal when items change
signal tool_broken(tool_name: String)
signal tool_repaired(tool_name: String)
signal watering_pot_emptied
signal watering_pot_refilled
signal equipped_tool_changed(tool_name: String) # If implementing tool selection

# Inventory data structures
var items: Dictionary = {} # item_name (String) -> quantity (int)
var tools: Dictionary = {} # tool_name (String) -> durability (int)
var tools_under_repair: Dictionary = {} # tool_name (String) -> completion_week (int)

# Watering Pot specific state
var watering_pot_level: int = 0
const WATERING_POT_CAPACITY: int = 5 # Max water charges

# Equipped tool (optional for now, but placeholder)
var equipped_tool: String = ""

func _ready() -> void:
	print("InventoryManager ready.")
	# Initialize starting inventory based on TDD/GDD
	_initialize_inventory()

	# ── NEW: listen for the calendar tick coming from TimeSystem ──
	# When the EventBus fires week_advanced, call our handler.
	# The signature of the signal is (int new_week, StringName new_season).
	EventBus.week_advanced.connect(_on_week_advanced)

func _on_week_advanced(new_week: int, _season: StringName) -> void:
	check_completed_repairs(new_week)

func _initialize_inventory() -> void:
	# Starting Tools (Durability based on TDD)
	add_tool("Hoe", 40)
	add_tool("Watering Pot", WATERING_POT_CAPACITY) # Durability for watering pot represents charges
	add_tool("Sickle", 50)
	add_tool("Mattock", 30) # Adding Mattock as per GDD/TDD tool list

	# Starting Seeds (Example quantities)
	add_item("Fast Greens Seed", 5) # Placeholder name for fast greens seeds
	add_item("Cabbage Seed", 3)
	add_item("Wheat Seed", 2) # Added Wheat seed based on prototype plants
	add_item("Sage Seed", 2) # Added Sage seed based on prototype plants

	# Starting Misc
	add_item("Fertilizer", 1) # Start with one fertilizer? (as per TDD suggestion)

	# Set initial water level
	watering_pot_level = WATERING_POT_CAPACITY

	print("Initial Inventory: ", items)
	print("Initial Tools: ", tools)
	print("Watering Pot Level: ", watering_pot_level, "/", WATERING_POT_CAPACITY)

# --- Item Management ---
func add_item(item_name: String, quantity: int) -> void:
	if items.has(item_name):
		items[item_name] += quantity
	else:
		items[item_name] = quantity
	inventory_updated.emit()
	print("Added ", quantity, " ", item_name, ". Total: ", items[item_name])

func remove_item(item_name: String, quantity: int) -> bool:
	if has_item(item_name, quantity):
		items[item_name] -= quantity
		if items[item_name] <= 0:
			items.erase(item_name) # Remove item if quantity is zero or less
		inventory_updated.emit()
		print("Removed ", quantity, " ", item_name, ". Remaining: ", items.get(item_name, 0))
		return true
	else:
		print("Failed to remove ", quantity, " ", item_name, ". Not enough in inventory.")
		return false

func has_item(item_name: String, quantity: int = 1) -> bool:
	return items.has(item_name) and items[item_name] >= quantity

func get_item_quantity(item_name: String) -> int:
	return items.get(item_name, 0)

# --- Tool Management ---
func add_tool(tool_name: String, initial_durability: int) -> void:
	if not tools.has(tool_name):
		tools[tool_name] = initial_durability
		inventory_updated.emit() # Might need a specific tool_added signal later
	else:
		# Handle potentially adding a duplicate tool? For now, just log.
		print("Tool ", tool_name, " already exists.")

func use_tool(tool_name: String) -> bool:
	if tool_name == "Watering Pot":
		# Special handling for watering pot charges
		return use_watering_pot_charge()

	if tools.has(tool_name) and tools[tool_name] > 0:
		tools[tool_name] -= 1
		print(tool_name, " durability: ", tools[tool_name])
		inventory_updated.emit() # Update UI potentially
		if tools[tool_name] <= 0:
			print(tool_name, " broke!")
			tool_broken.emit(tool_name)
			# Optionally remove from usable tools or just show durability 0? TBD.
			# For now, just leave durability at 0. Repair system will handle it.
		return true
	elif tools.has(tool_name) and tools[tool_name] <= 0:
		print(tool_name, " is broken!")
		# Potentially emit tool_broken again if needed, or rely on UI showing 0 durability
		return false
	else:
		print("Tool ", tool_name, " not found in inventory.")
		return false

func get_tool_durability(tool_name: String) -> int:
	return tools.get(tool_name, 0) # Return 0 if tool doesn't exist

func is_tool_broken(tool_name: String) -> bool:
	# A tool is considered broken if its durability is 0 or less.
	return tools.has(tool_name) and tools[tool_name] <= 0

# --- Watering Pot Specific ---
func get_watering_pot_level() -> int:
	return watering_pot_level

func use_watering_pot_charge() -> bool:
	if watering_pot_level > 0:
		watering_pot_level -= 1
		print("Used water. Level: ", watering_pot_level)
		inventory_updated.emit() # For UI update
		if watering_pot_level <= 0:
			watering_pot_emptied.emit()
			print("Watering pot empty!")
		return true
	else:
		print("Watering pot is empty. Cannot use water.")
		return false

func refill_watering_pot() -> void:
	if watering_pot_level < WATERING_POT_CAPACITY:
		watering_pot_level = WATERING_POT_CAPACITY
		print("Watering pot refilled.")
		inventory_updated.emit() # For UI update
		watering_pot_refilled.emit()
	else:
		print("Watering pot already full.")

# --- Tool Repair --- (Basic structure as per TDD)
func start_tool_repair(tool_name: String, repair_duration_weeks: int) -> void:
	if is_tool_broken(tool_name) and not tools_under_repair.has(tool_name):
		# Requires TimeSystem access to get current week
		if TimeSystem: # Check if TimeSystem Autoload is available
			var current_game_week = TimeSystem.current_week
			var completion_week = current_game_week + repair_duration_weeks
			tools_under_repair[tool_name] = completion_week
			tools.erase(tool_name) # Remove from active tools while being repaired
			inventory_updated.emit()
			print(tool_name, " sent for repair. Ready on week ", completion_week)
		else:
			printerr("Cannot start repair: TimeSystem not found.")
	elif tools_under_repair.has(tool_name):
		print(tool_name, " is already under repair.")
	elif not is_tool_broken(tool_name):
		print("Cannot repair ", tool_name, ": It's not broken.")

func check_completed_repairs(current_game_week: int) -> Array[String]:
	var completed_tools: Array[String] = []
	for tool_name in tools_under_repair:
		if current_game_week >= tools_under_repair[tool_name]:
			completed_tools.append(tool_name)

	# Process completions outside the loop to avoid modifying dictionary during iteration
	for tool_name in completed_tools:
		complete_tool_repair(tool_name)

	return completed_tools # Return list of tools just completed (for notifications)

func complete_tool_repair(tool_name: String) -> void:
	if tools_under_repair.has(tool_name):
		print(tool_name, " repair complete!")
		tools_under_repair.erase(tool_name)
		# Find original durability - needs a better system later, maybe store max durability?
		# For prototype, just restore to a default value. Let's use the initial ones for now.
		var restored_durability = 0
		match tool_name:
			"Hoe": restored_durability = 40
			"Sickle": restored_durability = 50
			"Mattock": restored_durability = 30
			# Add other repairable tools here if needed
			_: restored_durability = 10 # Default fallback

		add_tool(tool_name, restored_durability) # Use add_tool to put it back
		tool_repaired.emit(tool_name)
		# No need for inventory_updated here as add_tool emits it
	else:
		printerr("Attempted to complete repair for ", tool_name, " which wasn't being repaired.")

# --- Equipped Tool --- (Basic)
func set_equipped_tool(tool_name: String) -> void:
	if tools.has(tool_name) or tool_name == "": # Allow un-equipping
		if equipped_tool != tool_name:
			equipped_tool = tool_name
			print("Equipped: ", tool_name if tool_name != "" else "None")
			equipped_tool_changed.emit(tool_name)
	else:
		print("Cannot equip ", tool_name, ": Not in inventory or not a valid tool.")

func get_equipped_tool() -> String:
	return equipped_tool
