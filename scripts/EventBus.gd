extends Node
## ------------------------------------------------------------------
## EventBus.gd – central signal hub (Godot 4.4.1)
##
## This script only *declares* signals; it owns no gameplay logic.
## Any system can broadcast an event with:
##     EventBus.week_advanced.emit(new_week, new_season)
## and listen with:
##     EventBus.week_advanced.connect(my_callable)
##
## Centralising signals keeps subsystems decoupled and prevents
## tangled node paths such as `get_node("../SomeManager")`.
## ------------------------------------------------------------------

# ───  Time ──────────────────────────────────────────────────────────
signal week_advanced(new_week: int, new_season: StringName)
signal day_advanced(new_day: int)

# ───  Inventory ────────────────────────────────────────────────────
signal inventory_changed()

# ───  Tools ────────────────────────────────────────────────────────
signal tool_broken(tool_id: StringName)
signal tool_repaired(tool_id: StringName)

# ───  Garden / Plots ───────────────────────────────────────────────
signal plot_state_changed(plot_id: StringName, new_state: int)

# ───  Quests ───────────────────────────────────────────────────────
signal quest_completed(quest_id: StringName)
signal quest_updated(quest_id: StringName, progress: float)

# ───  Helper: safe dynamic emission ────────────────────────────────
## Emits the given signal **only if** it exists on this EventBus.
## Usage example:
##     EventBus.emit_if_exists("inventory_changed", [])
##     EventBus.emit_if_exists("week_advanced", [5, "Spring"])
func emit_if_exists(signal_name: StringName, args: Array = []) -> void:
	if not has_signal(signal_name):
		push_warning("EventBus has no signal called '%s'" % signal_name)
		return
		
	var call_args: Array = [signal_name]
	call_args.append_array(args)
	callv("emit_signal", call_args)
