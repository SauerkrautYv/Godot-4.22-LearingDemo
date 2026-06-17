extends Node2D

# 存储连接点（使用本地坐标系）
var connection_points = {
	"left": [],  # 左侧连接点的单元格坐标（Vector2i）
	"right": [],
	"top": [],   # 新增
	"bottom": [] # 新增
}
enum ExitDirection { LEFT, RIGHT, TOP, BOTTOM }

@onready var tile_map: TileMap = $TileMap
@onready var 连接导航图块集: TileMap = $"连接导航图块集"


func _ready():
	scan_connection_points()
	print("左连接点：", connection_points["left"])
	print("右连接点：", connection_points["right"])
	print("上连接点：", connection_points["top"])
	print("下连接点：", connection_points["bottom"])

func scan_connection_points():
	# 扫描连接点图层
	var layer_id = 0
	for cell in 连接导航图块集.get_used_cells(layer_id):
		var atlas_coords = 连接导航图块集.get_cell_atlas_coords(layer_id, cell)
		# 假设：
		# (0,0) -> left
		# (1,0) -> right
		# (2,0) -> top
		# (3,0) -> bottom
		if atlas_coords == Vector2i(0, 11):
			connection_points["left"].append(cell)
		elif atlas_coords == Vector2i(2, 11):
			connection_points["right"].append(cell)
		elif atlas_coords == Vector2i(0, 13):
			connection_points["top"].append(cell)
		elif atlas_coords == Vector2i(2, 13):
			connection_points["bottom"].append(cell)

func open_exit(direction: ExitDirection):
	var direction_key: String
	match direction:
		ExitDirection.LEFT: direction_key = "left"
		ExitDirection.RIGHT: direction_key = "right"
		ExitDirection.TOP: direction_key = "top"
		ExitDirection.BOTTOM: direction_key = "bottom"
		_: 
			push_error("无效的方向!")
			return
	
	# 获取要清除的单元格列表
	print("实际清除的方向键:", direction_key)  # 调试输出
	var cells_to_clear: Array = connection_points.get(direction_key, [])

	# 在主体TileMap上清除对应位置的图块（假设墙壁在图层0）
	var wall_layer := 1
	for cell_pos in cells_to_clear:
		tile_map.set_cell(wall_layer, cell_pos, -1)#-1表示清除图块

	 #Godot 4 会自动更新地形连接，无需手动调用额外方法
	 #如果未生效，可能需要重新设置相邻图块
	 #强制更新周围地形
	var positions: Array[Vector2i] = []
	for cell_pos in cells_to_clear:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var neighbor_pos = cell_pos + Vector2i(dx, dy)
				# 重新设置相邻图块（触发地形逻辑）
				var existing_id = tile_map.get_cell_source_id(1, neighbor_pos)
				if existing_id != -1:
					if not positions.has(neighbor_pos):
						positions.append(neighbor_pos)
	tile_map.set_cells_terrain_connect(wall_layer,positions,1,0,false)
	
