extends Node2D

@export var fade_time := 0.8  # 渐隐时间
@export var float_height := 50.0  # 上浮高度

@export var text := "MISS":
	set(value):
		$Label.text = TranslationServer.translate(value)

func _ready():
	# 初始位置随机偏移（避免重叠）
	position += Vector2(randf_range(-20, 20), 0)
	
	# 上浮动画
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - float_height, fade_time)
	tween.parallel().tween_property($Label, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)  # 动画结束后删除
