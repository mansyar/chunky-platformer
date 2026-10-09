extends AreaBuilder
## The meadow: the first area, and the one a child plays first.
##
## Everything this level used to hand-place lives in AreaLayout.meadow(); this
## script is now just the scene Godot opens. The cave and the sunset are the
## same two lines with a different layout.


func _ready() -> void:
	build(AreaLayout.meadow())
