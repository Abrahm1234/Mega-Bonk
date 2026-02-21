extends Node

# DisjointSet Class for Union-Find
class DisjointSet:
	var parent = {}
	var rank = {}

	func _init():
		parent.clear()
		rank.clear()

	func find(x):
		if not parent.has(x):
			parent[x] = x
			rank[x] = 0
		if parent[x] != x:
			parent[x] = find(parent[x])  # Path compression
		return parent[x]

	func union(x, y):
		var root_x = find(x)
		var root_y = find(y)

		if root_x != root_y:
			if rank[root_x] < rank[root_y]:
				parent[root_x] = root_y
			elif rank[root_x] > rank[root_y]:
				parent[root_y] = root_x
			else:
				parent[root_y] = root_x
				rank[root_x] += 1

# Custom comparator for sorting edges by weight
func compare_edges(edge_a, edge_b) -> bool:
	return int(edge_a[2]) < int(edge_b[2])

# Kruskal's algorithm to find the MST
func kruskal_mst(edges: Array) -> Array:
	"""
	Finds the Minimum Spanning Tree (MST) of a graph using Kruskal's algorithm.

	Args:
		edges: Array of tuples, where each tuple is (node1, node2, weight).

	Returns:
		Array of edges forming the MST.
	"""
	if edges.size() == 0:  # Replaced `empty()` with size check
		push_error("No edges provided. Returning an empty MST.")
		return []

	# Ensure edges are formatted correctly
	for edge in edges:
		if edge.size() != 3 or not (edge[2] is float or edge[2] is int):
			push_error("Invalid edge format: Each edge must be (node1, node2, weight).")
			return []

	# Sort edges by weight
	edges.sort_custom(compare_edges)

	var mst = []  # Store MST edges
	var disjoint_set = DisjointSet.new()
	disjoint_set._init()

	for edge in edges:
		var node1 = edge[0]
		var node2 = edge[1]
		if disjoint_set.find(node1) != disjoint_set.find(node2):
			mst.append(edge)
			disjoint_set.union(node1, node2)

	return mst

# Example usage
func _ready():
	var edges = [
		["A", "B", 1],
		["B", "C", 2],
		["C", "A", 3],
		["B", "D", 4]
	]
	var mst = kruskal_mst(edges)
	print("MST:", mst)
