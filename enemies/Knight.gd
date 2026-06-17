extends Enemy

enum State{
	IDLE,
	WALK,
	RUN,
	ATTACK,
	ROLL,
	JUMP_ROLL,
	HURT,
	STUN,
	DYING,
}

var pending_damage:Damage
var is_first_tick := false
var attack_count := 0

const KNOCKBACK_AMOUNT := 10.0			#击退
const MAX_ATTACKS_BEFORE_FATIGUE := 5	#攻击5次后疲惫

@onready var attack_checker: RayCast2D = $Graphics/AttackChecker
@onready var attack_checker_2: RayCast2D = $Graphics/AttackChecker2
@onready var walk_checker: RayCast2D = $Graphics/WalkChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker

@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var stun_timer: Timer = $StunTimer
@onready var attack_cd_timer: Timer = $AttackCDTimer
@onready var spawn_coin_timer: Timer = $SpawnCoinTimer

@onready var sweat_icon: AnimatedSprite2D = $Graphics/SweatIcon
@onready var stun_icon: AnimatedSprite2D = $StunIcon
@onready var earthquake_wave_icon: AnimatedSprite2D = $EarthquakeWaveIcon
@onready var anger_icon: AnimatedSprite2D = $Graphics/AngerIcon

@onready var dameged_audio: AudioStreamPlayer = $DamegedAudio
@onready var coin_audio: AudioStreamPlayer = $CoinAudio
@onready var roll_audio: AudioStreamPlayer = $RollAudio
@onready var jump_audio: AudioStreamPlayer = $JumpAudio
@onready var fall_audio: AudioStreamPlayer = $FallAudio

@onready var shock_wave_collision_shape_2d: CollisionShape2D = $OtherHitbox/ShockWaveCollisionShape2D

func _ready():
	super._ready()#调用父类的_ready()
	#手动连接信号
	#地震波动画帧
	earthquake_wave_icon.frame_changed.connect(_on_ShockwaveSprite_animation_frame_triggered)

func can_see_player() -> bool:
	if walk_checker.is_colliding():
		return false
	return player_checker.is_colliding()

func get_direction_toward_player() -> void:
	var player = get_node("../player")
	if player.global_position.x < global_position.x:
		direction = Direction.LEFT  # 向左移动
	elif player.global_position.x > global_position.x:
		direction = Direction.RIGHT   # 向右移动
	else:
		direction = direction   # 不需要水平移动

func tick_physics(state:State ,delte:float) -> void:
	stun_icon.visible = stun_timer.time_left > 0
	sweat_icon.visible = attack_cd_timer.time_left > 0
	match state:
		State.IDLE:
			move(0.0,delte)
		State.ATTACK:
			if is_first_tick:
				move(0.0,delte,true,0)
			else:
				move(0.0,delte)
		State.STUN:
			move(0.0,delte)
		State.WALK:
			if walk_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed/4,delte)
		State.RUN:
			get_direction_toward_player()
			move(max_speed/2,delte)
			if can_see_player():
				calm_down_timer.start()
		State.ROLL:
			move(max_speed/1.6,delte)
		State.JUMP_ROLL:
			if is_first_tick:
				move(max_speed/1.8,delte,true,0)
			else:
				move(max_speed/1.8,delte)
		State.DYING,State.HURT:
			move(0.0,delte)
	is_first_tick = false

func get_next_state(state:State) -> int:
	if stats.health <= 0:
		return StateMachine.KEEP_CURRENT if state == State.DYING else State.DYING#State.DYING
	if pending_damage:
		stats.health -= pending_damage.amount
		var dir := pending_damage.source.global_position.direction_to(global_position)#来源指向自己
		velocity = dir * KNOCKBACK_AMOUNT
		if dir.x>0:
			direction = Direction.LEFT
		else:
			direction = Direction.RIGHT
		pending_damage = null
		return State.HURT
	if stun_timer.time_left > 0 and state !=State.HURT:
		if state !=State.STUN:
			return State.STUN
		else:
			return StateMachine.KEEP_CURRENT
	match state:
		State.IDLE:
			if can_see_player() and floor_checker.is_colliding() and not attack_cd_timer.time_left > 0:
				return State.RUN
			if state_machine.state_time > 2 and not attack_cd_timer.time_left > 0:
				return State.WALK
		State.WALK:
			if can_see_player() and floor_checker.is_colliding():
				return State.RUN
			if not floor_checker.is_colliding():
				return State.IDLE
			if state_machine.state_time > 2:
				return State.RUN
		State.RUN:
			if attack_checker_2.is_colliding():
				var attack_states = [State.JUMP_ROLL, State.ROLL]
				return attack_states[randi() % attack_states.size()]
			if attack_checker.is_colliding():
				var attack_states = [State.ATTACK,State.ROLL]
				return attack_states[randi() % attack_states.size()]
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
		State.HURT:
			if not animation_player.is_playing():
				if stun_timer.time_left > 0:
					return State.STUN
				if attack_cd_timer.time_left > 0:
					return State.IDLE
				return State.RUN
		State.STUN:
			if stun_timer.is_stopped():
				return State.IDLE
			if not animation_player.is_playing():
				return State.IDLE
		State.ATTACK:
			if is_on_floor() and not is_first_tick:
				stun(0.8)
				spawn_shockwave()
				if attack_count >= MAX_ATTACKS_BEFORE_FATIGUE:
					attack_cd_timer.start()
				return State.IDLE
			if not animation_player.is_playing():
				return State.WALK
		State.ROLL:
			if not animation_player.is_playing():
				if attack_count >= MAX_ATTACKS_BEFORE_FATIGUE:
					attack_cd_timer.start()
					return State.IDLE
				return State.RUN
		State.JUMP_ROLL:
			if not animation_player.is_playing():
				if attack_count >= MAX_ATTACKS_BEFORE_FATIGUE:
					attack_cd_timer.start()
					return State.IDLE
				return State.RUN
	return StateMachine.KEEP_CURRENT#state#

func transition_state(from: State,to: State) ->void:
	print("[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<State>",
		State.keys()[to],
	])

	match to:
		State.IDLE:
			animation_player.play("idle")
			if not floor_checker.is_colliding():
				direction *= -1
				#floor_checker.force_raycast_update()
		State.WALK:
			animation_player.play("run")
			if not floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update()
		State.RUN:
			animation_player.play("run")
		State.ROLL:
			attack_count += 1
			roll_audio.play()
			animation_player.play("roll")
		State.JUMP_ROLL:
			attack_count += 1
			velocity.y = -330
			jump_audio.play()
			animation_player.play("roll")
		State.HURT:
			dameged_audio.play()
			animation_player.play("hit")
		State.STUN:
			animation_player.play("stun")
		State.ATTACK:
			attack_count += 1
			velocity.y = -440
			jump_audio.play()
			animation_player.play("attack")
		State.DYING:
			animation_player.play("die")
	is_first_tick = true

func stun(duration: float):
	stun_timer.start(duration)

#地震波
func spawn_shockwave():
	earthquake_wave_icon.visible = true
	earthquake_wave_icon.frame = 0  # 重置帧
	earthquake_wave_icon.play("play")  # 播放动画
	fall_audio.play()

func _on_hurtbox_hurt(hitbox: Variant) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner


func _on_earthquake_wave_icon_animation_finished() -> void:
	earthquake_wave_icon.visible = false

# 地震波
# 手动连接信号
func _on_ShockwaveSprite_animation_frame_triggered():
	if earthquake_wave_icon.animation == "play" and earthquake_wave_icon.frame == 1:
		shock_wave_collision_shape_2d.disabled = false  # 在特定帧激活伤害
	if earthquake_wave_icon.animation == "play" and earthquake_wave_icon.frame == 3:
		shock_wave_collision_shape_2d.disabled = true  # 在特定帧关闭伤害


var falling_object_scene: PackedScene = preload("res://Objects/bullet/bullet_coin.tscn")
@export var spawn_range := 64.0   # 玩家周围生成范围
func spawn_falling_coin():
	print(0)
	var player = get_node("../player")
	print(1)
	# 在玩家周围随机位置生成
	for i in 2:  # 每次召唤3个
		var obj = falling_object_scene.instantiate()
		obj.target_position = player.global_position + Vector2(
			randf_range(-spawn_range, spawn_range), 
			-100  # 从屏幕上方掉落
		)
		obj.global_position = Vector2(
			obj.target_position.x, 
			player.global_position.y - 500  # 从高处下落
		)
		# 预警特效（可选）
		print(2)
		spawn_warning_marker(obj.target_position)
		get_parent().add_child(obj)  # 添加到场景
	coin_audio.play()

func spawn_warning_marker(pos: Vector2):
	var marker = preload("res://Objects/warning_tip.tscn").instantiate()
	marker.position = pos
	marker.z_index = 100  # 确保显示在最上层
	get_parent().add_child(marker)
	## 1秒后移除预警
	#await get_tree().create_timer(1.0).timeout
	#marker.queue_free()

func _on_spawn_coin_timer_timeout() -> void:
	spawn_falling_coin()


func _on_attack_cd_timer_timeout() -> void:
	attack_count = 0  # 重置计数器
