@tool
extends Marker2D

@export var 出口方向 := ExitDirection.DOWN  # 预设方向枚举
@export var 出口宽度 := 4 :            # 出口宽度(格数)
	set(v):
		出口宽度 = max(1, v)  # 确保不小于1
@onready var tile_map: TileMap = $"../TileMap"

enum ExitDirection {
	UP, DOWN, LEFT, RIGHT,
	UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT 
}

func _ready():
	if Engine.is_editor_hint():
		_snap_to_grid()
		queue_redraw()

func _draw():
	if Engine.is_editor_hint():
		_draw_visual_guides()

func get_direction_vector() -> Vector2i:
	match 出口方向:
		ExitDirection.UP:         return Vector2i.UP
		ExitDirection.DOWN:       return Vector2i.DOWN
		ExitDirection.LEFT:       return Vector2i.LEFT
		ExitDirection.RIGHT:      return Vector2i.RIGHT
		ExitDirection.UP_LEFT:    return Vector2i(-1, -1)
		ExitDirection.UP_RIGHT:   return Vector2i(1, -1)
		ExitDirection.DOWN_LEFT:  return Vector2i(-1, 1)
		ExitDirection.DOWN_RIGHT: return Vector2i(1, 1)
		_: return Vector2i.ZERO

# 获取出口的网格坐标
func get_cell_position() -> Vector2i:
	return tile_map.local_to_map(position)

# 获取出口的矩形区域（世界坐标）
func get_exit_rect() -> Rect2:
	var dir = get_direction_vector()
	var cell_size = tile_map.cell_size
	var center = global_position

	if dir.x != 0: # 水平出口
		return Rect2(
			center - Vector2(出口宽度 * cell_size.x / 2.0, cell_size.y / 2.0),
			Vector2(出口宽度 * cell_size.x, cell_size.y))
	else: # 垂直出口
		return Rect2(
		center - Vector2(cell_size.x / 2.0, 出口宽度 * cell_size.y / 2.0),
		Vector2(cell_size.x, 出口宽度 * cell_size.y))

# 私有方法
func _snap_to_grid():
	position = position.snapped(tile_map.cell_size / 2.0)
	var cell = get_cell_position()
	var map_rect = Rect2i(Vector2i.ZERO, tile_map.get_used_rect().size)
	if not map_rect.has_point(cell):
		position = tile_map.map_to_local(map_rect.get_closest_point(cell))

func _draw_visual_guides():
	var dir = get_direction_vector() * 16
	draw_line(Vector2.ZERO, dir, Color.GREEN, 2)
	_draw_triangle(dir, dir.rotated(PI*0.8).normalized() * 8)
	var width_px = 出口宽度 * tile_map.cell_size.x
	var perpendicular = Vector2(dir.y, -dir.x).normalized()
	draw_line(perpendicular * width_px/2.0, -perpendicular * width_px/2.0, Color.RED, 2)

func _draw_triangle(pos: Vector2, tip_offset: Vector2):
	var points = PackedVector2Array([pos, pos+tip_offset, pos-tip_offset])
	var colors = PackedColorArray([Color.GREEN, Color.GREEN, Color.GREEN])
	draw_polygon(points, colors)
