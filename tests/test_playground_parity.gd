extends GdToolsTest
## Frozen regression snapshot of the meadow terrain.
##
## These runs were dumped from the hand-built playground on 2026-10-09, before
## the shared-builder refactor turned it into a layout record. Once the
## playground IS the builder, a test comparing the two would only prove the
## builder equals itself - so the expected shape is pinned here instead. If a
## future change moves a single tile, this fails.

const PLAYGROUND_SCENE := "res://src/levels/playground.tscn"

## Format "row:first_col-last_col", inclusive, one entry per horizontal run of
## filled cells. Decoration and trampoline pads appear as isolated single
## cells, which is why they are here too.
const EXPECTED_RUNS: PackedStringArray = [
	"23:32-32",
	"23:35-35",
	"23:37-37",  # tufts, flowers and rocks on the tall plateau
	"24:30-39",  # tall hill plateau surface
	"25:30-39",
	"26:28-39",  # tall hill top step merges into the plateau
	"27:3-3",
	"27:8-8",
	"27:10-11",
	"27:28-39",
	"28:0-11",
	"28:26-39",  # low plateau surface / tall hill middle step
	"29:0-11",
	"29:26-39",
	"30:0-13",
	"30:24-39",  # the two lowest steps meet the ground
	"31:0-13",
	"31:17-17",
	"31:20-20",
	"31:22-22",
	"31:24-39",  # pads + valley deco
	"32:0-39",  # the ground floor, full width
	"33:0-39",
]


func _runs_of(tile_map: TileMapLayer, layout: AreaLayout) -> PackedStringArray:
	var runs := PackedStringArray()
	for y: int in layout.rows:
		var start := -1
		for x: int in layout.cols:
			var filled := tile_map.get_cell_source_id(Vector2i(x, y)) != -1
			if filled and start == -1:
				start = x
			elif not filled and start != -1:
				runs.append("%d:%d-%d" % [y, start, x - 1])
				start = -1
		if start != -1:
			runs.append("%d:%d-%d" % [y, start, layout.cols - 1])
	return runs


func _find_tile_map(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node as TileMapLayer
	for child: Node in node.get_children():
		var found := _find_tile_map(child)
		if found != null:
			return found
	return null


func test_playground_paints_the_frozen_meadow_terrain() -> void:
	var level: Node = load(PLAYGROUND_SCENE).instantiate()
	add_child(level)
	var layout := AreaLayout.meadow()
	var actual := _runs_of(_find_tile_map(level), layout)
	assert_eq(
		actual,
		EXPECTED_RUNS,
		"the meadow terrain is byte-for-byte the terrain a child has already played"
	)


func test_the_snapshot_is_not_trivially_empty() -> void:
	# Guards the guard: an empty or short snapshot would make the comparison
	# above pass for the wrong reason.
	assert_gt(EXPECTED_RUNS.size(), 15, "the snapshot covers the whole level.")
	var cells := 0
	for run: String in EXPECTED_RUNS:
		var bounds: PackedStringArray = run.split(":")
		var span: PackedStringArray = bounds[1].split("-")
		cells += int(span[1]) - int(span[0]) + 1
	assert_gt(cells, 200, "the snapshot covers the whole level, not a corner of it.")
