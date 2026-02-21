extends Node

class_name PriorityQueue

# Internal storage for the queue
var queue: Array = []

# Adds an item to the queue with the given priority
func enqueue(item: Variant, priority: float) -> void:
	queue.append({"item": item, "priority": priority})
	queue.sort_custom(Callable(self, "_compare"))  # Sort by priority (lowest comes first)

# Removes and returns the item with the highest priority (lowest value)
func dequeue() -> Variant:
	if queue.size() > 0:
		return queue.pop_front()["item"]  # Remove the first item in the sorted queue
	else:
		push_error("Attempted to dequeue from an empty PriorityQueue.")
		return null

# Checks if the queue is empty
func is_empty() -> bool:
	return queue.is_empty()

# Determines if the queue contains a specific item
func contains(item: Variant) -> bool:
	for entry in queue:
		if entry["item"] == item:
			return true
	return false

# Compares two entries in the queue based on their priority
func _compare(a: Dictionary, b: Dictionary) -> bool:
	return a["priority"] < b["priority"]  # Lower priority values come first
