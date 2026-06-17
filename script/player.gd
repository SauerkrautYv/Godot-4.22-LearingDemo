class_name Player
extends CharacterBody2D

const RUN_SPEED := 200.0
const SPIKES_SPEED := 450.0
const SLIDER_TIME := 0.3
const SLIDING_SPEED := 220.0
const ACCELERATION := RUN_SPEED/ 0.2
const AIR_ACCELERATION := RUN_SPEED/ 0.4

const KNOCKBACK_AMOUNT := 200.0#击退

const JUMP_VALOCTIY := -350
const WALL_JUMP_VALOCTIY := Vector2(260,-300)
const BACK_JUMP_VALOCTIY := Vector2(-260,-250)

const LANDING_HEIGHT := 100.0

const JUMPING_COST := 1.2
const UP_ATTACK_COST := 2.4
const BLOCK_COST := 2.2
const BLOCK_CONTINUE_COST := 2.0
const SLIDING_COST := 3.0
const SPELLING_COST := 7.0


enum Direction{
	LEFT = -1,
	RIGHT = 1,
}

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	BACK_JUMP_ATTACK,
	BACK_JUMP,
	AIR_ATTACK,
	AIR_FALL_ATTACK,
	SPIKES,
	BLOCK_START,
	BLOCK,
	PARRY,#弹反状态
	SPELL,
	CLIMBING,
	CLIMB_IDLE,
	HURT,
	DYING,
	SLIDING_START,
	SLIDING_LOOP,
	SLIDING_END,
}
const GROUND_STATES := [
	State.IDLE,State.RUNNING,State.LANDING,
	State.ATTACK_1,State.ATTACK_2,State.ATTACK_3,
	]#地面状态

@export var can_combo := false#在动画中变化
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false
var is_floated := false
var is_combo_requested := false
var pending_damage : Damage
var fall_form_y :float
var interacting_with: Array[Interactable]
var pending_counter_attack := false#弹反
var bullet = preload("res://Objects/bullet/missile.tscn")#子弹

@onready var graphics: Node2D = $Graphics
@onready var animation_player = $AnimationPlayer

@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = Game.player_stats

@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var slide_request_timer: Timer = $SlideRequestTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var block_timer: Timer = $BlockTimer

@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var climb_checker: RayCast2D = $Graphics/ClimbChecker

@onready var interaction_icon: AnimatedSprite2D = $InteractionICON

@onready var lanch_point: Marker2D = $LanchPoint

@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var pause_screen: Control = $CanvasLayer/PauseScreen
@onready var bag_screen: Control = $CanvasLayer/bag_screen



func _ready() -> void:
	stand(default_gravity,0.01)

func _unhandled_input(event: InputEvent) -> void:#输入事件的处理函数
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VALOCTIY/2:#是否长按控制跳跃速度
			velocity.y =  JUMP_VALOCTIY/2
	if event.is_action_pressed("attack") and can_combo:#攻击输入缓存用来触发连击动作
		is_combo_requested = true
	if event.is_action_pressed("slide"):
		slide_request_timer.start()
	if event.is_action_pressed("interact") and interacting_with:
		interacting_with.back().interact()#最后一个元素
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()
	if event.is_action_pressed("bag"):
		if bag_screen.visible == false:
			bag_screen.show_screen()
		else:
			bag_screen.hide()
		get_window().set_input_as_handled()#停止事件传播，防止关闭后又E开启

func tick_physics(state:State,delta:float) -> void:
	interaction_icon.visible = not interacting_with.is_empty()
	
	if invincible_timer.time_left > 0:#无敌时间
		graphics.modulate.a = sin(Time.get_ticks_msec()/10)*0.5+0.5
	else:
		graphics.modulate.a = 1
	
	match state:
		State.IDLE:
			move(default_gravity,delta)
		State.RUNNING:
			move(default_gravity,delta)
		State.CLIMBING:
			climb(default_gravity,delta)
		State.JUMP:
			if is_first_tick and not is_floated:
				move(0.0,delta)
			else:
				move(default_gravity,delta)
		State.BACK_JUMP:
			if state_machine.state_time < 0.1:
				stand(0.0 if is_first_tick else default_gravity,delta)
			else:
				move(default_gravity,delta)
		State.FALL:
			move(default_gravity,delta)
		State.LANDING:
			#pass
			stand(default_gravity,delta)
		State.WALL_SLIDING:
			move(default_gravity/4,delta)
			direction = Direction.LEFT if -get_wall_normal().x < 0 else Direction.RIGHT
		State.WALL_JUMP:
			if state_machine.state_time < 0.1:
				stand(0.0 if is_first_tick else default_gravity,delta)
				direction = Direction.LEFT if get_wall_normal().x < 0 else Direction.RIGHT
			else:
				move(default_gravity,delta)
		State.SPIKES:
			if is_first_tick:
				spikes(default_gravity,delta)
			stand(default_gravity,delta)
		State.ATTACK_1,State.ATTACK_2,State.ATTACK_3:
			stand(default_gravity,delta)
		State.AIR_ATTACK:
			floating(default_gravity,delta)
		State.AIR_FALL_ATTACK:
			stand(default_gravity,delta)
		State.BACK_JUMP_ATTACK:
			stand(default_gravity,delta)
		State.SPELL:
			stand(default_gravity,delta)
		State.BLOCK_START:
			stand(default_gravity,delta)
		State.BLOCK:
			move(default_gravity,delta)
			#持续消耗耐力
			stats.energy -= BLOCK_CONTINUE_COST * delta
		State.PARRY:
			stand(default_gravity,delta)
		State.SLIDING_END:
			stand(default_gravity,delta)
		State.SLIDING_START,State.SLIDING_LOOP:
			slide(default_gravity,delta)
		State.HURT,State.DYING:
			stand(default_gravity,delta)
	is_first_tick = false#按帧执行后必定不为第一帧


func move(gravity: float,delta:float) -> void:
	var movementX := Input.get_axis("move_left","move_right")
	var acceleration := ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, movementX * RUN_SPEED,acceleration * delta)
	velocity.y += gravity * delta#重力在jump状态第一帧时输入为0
	
	if not is_zero_approx(movementX):
		direction = Direction.LEFT if movementX < 0 else Direction.RIGHT
	move_and_slide()

func floating(gravity: float,delta:float) -> void:
	var movement := Input.get_axis("move_left","move_right")
	var acceleration := ACCELERATION if is_on_floor() else AIR_ACCELERATION
	#velocity.x = move_toward(velocity.x,0.0,AIR_ACCELERATION * delta)
	velocity.y = 0
	move_and_slide()

func stand(gravity: float,delta:float) -> void:
	var acceleration := ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x,0.0,acceleration * delta)
	velocity.y += gravity * delta#重力在jump状态第一帧时输入为0
	move_and_slide()

func climb(gravity:float,delta:float) ->void:
	
	var movement := Vector2.ZERO
	movement.y = Input.get_axis("move_down","move_up")
	movement.x = Input.get_axis("move_left","move_right")
	print(1)
	if movement:
		animation_player.play()
		print(2)
		velocity.y = movement.y * JUMP_VALOCTIY/2
		velocity.x = move_toward(velocity.x, movement.x * -JUMP_VALOCTIY,AIR_ACCELERATION * delta)
	else:
		velocity = Vector2.ZERO
		animation_player.stop()
	move_and_slide()

func slide(gravity:float,delta:float) ->void:
	velocity.x = graphics.scale.x * SLIDING_SPEED
	velocity.y += gravity * delta#默认重力
	move_and_slide()

func spikes(gravity:float,delta:float) ->void:
	velocity.x = graphics.scale.x * SPIKES_SPEED
	velocity.y += gravity * delta#默认重力
	move_and_slide()

func can_wall_slide() -> bool:
	return hand_checker.is_colliding() and foot_checker.is_colliding()#有BUGis_on_wall()不使用按键时不检测#is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding()

func should_slide() ->bool:
	if slide_request_timer.is_stopped():
		return false
	if stats.energy < SLIDING_COST:
		return false
	return not foot_checker.is_colliding()

func can_jump(state:State) ->bool:
	if stats.energy < JUMPING_COST:
		return false
	if state == State.LANDING:
		return false
	return is_on_floor() or coyote_timer.time_left > 0 or state == State.CLIMBING

func get_next_state(state: State) -> int:
	if stats.health <= 0:
		return StateMachine.KEEP_CURRENT if state == State.DYING else State.DYING#State.DYING
	if pending_damage:
		return State.HURT
	
	#var can_jump := state != State.LANDING and is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump(state) and jump_request_timer.time_left > 0 #Input.is_action_just_pressed("jump")
	if should_jump:
		return State.JUMP
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL
	if Input.is_action_just_pressed("move_up") and climb_checker.get_collider() and state != State.CLIMBING:
		return State.CLIMBING
	var movement := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(movement) and velocity.x < 32 #and is_zero_approx(velocity.x):#不会滑步
	
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("up_attack") and stats.energy > UP_ATTACK_COST:
				return State.BACK_JUMP_ATTACK
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if Input.is_action_pressed("block") and stats.energy > BLOCK_COST:
				stats.energy -= BLOCK_COST
				if block_timer.time_left > 0:#精防后连续防御
					return State.BLOCK
				else:
					return State.BLOCK_START
			if Input.is_action_pressed("spell") and stats.energy > SPELLING_COST:
				return State.SPELL
			if should_slide():
				return State.SLIDING_START
			if not is_still:
				return State.RUNNING
		State.RUNNING:
			if Input.is_action_just_pressed("up_attack") and stats.energy > UP_ATTACK_COST:
				return State.SPIKES
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if Input.is_action_just_pressed("block") and stats.energy > BLOCK_COST:
				stats.energy -= BLOCK_COST
				if block_timer.time_left > 0:#精防后连续防御
					return State.BLOCK
				else:
					return State.BLOCK_START
			if Input.is_action_pressed("spell") and stats.energy > SPELLING_COST:
				return State.SPELL
			if should_slide():
				return State.SLIDING_START
			if is_still:
				return State.IDLE
		State.CLIMBING:
			if not climb_checker.get_collider():
				return State.IDLE
			if Input.is_action_just_pressed("move_down") and is_on_floor():
				return State.IDLE
		State.JUMP:
			if Input.is_action_just_pressed("up_attack") and stats.energy > UP_ATTACK_COST:
				return State.AIR_FALL_ATTACK
			if Input.is_action_just_pressed("attack") and not is_floated:
				return State.AIR_ATTACK
			if  velocity.y >= 0:
				return State.FALL
		State.FALL:
			if Input.is_action_just_pressed("up_attack") and stats.energy > UP_ATTACK_COST:
				return State.AIR_FALL_ATTACK
			if Input.is_action_just_pressed("attack") and not is_floated:
				return State.AIR_ATTACK
			if is_on_floor():
				is_floated = false
				var height := global_position.y - fall_form_y
				return State.LANDING if height >= LANDING_HEIGHT else State.RUNNING#落地不会landing
			if can_wall_slide():
				is_floated = false
				return State.WALL_SLIDING
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0 and not is_first_tick:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if not can_wall_slide():
				return State.FALL
		State.WALL_JUMP:
			if can_wall_slide() and not is_first_tick:
				return State.WALL_SLIDING
			if  velocity.y >= 0:
				return State.FALL
		State.BACK_JUMP:
			if state_machine.state_time > 0.1:
				if Input.is_action_just_pressed("up_attack") and stats.energy > UP_ATTACK_COST:
					return State.AIR_FALL_ATTACK
				if Input.is_action_just_pressed("attack") and not is_floated:
					return State.AIR_ATTACK
			if  velocity.y >= 0:
				return State.FALL
		State.BACK_JUMP_ATTACK:
			if not animation_player.is_playing():
				return State.BACK_JUMP
		State.SPIKES:
			if not animation_player.is_playing():
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		State.ATTACK_1:
			if not animation_player.is_playing():
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		State.ATTACK_2:
			if not animation_player.is_playing():
				return State.ATTACK_3 if is_combo_requested else State.IDLE
		State.ATTACK_3:
			if not animation_player.is_playing():
				return State.ATTACK_1 if is_combo_requested else State.IDLE
		State.AIR_ATTACK:
			if not animation_player.is_playing():
				if  velocity.y >= 0:
					return State.FALL
				else:
					return State.JUMP
		State.AIR_FALL_ATTACK:
			if not animation_player.is_playing():
				if  velocity.y >= 0:
					return State.FALL
				else:
					return State.JUMP
		State.SPELL:
			if not animation_player.is_playing():
				bullet_creat()
				return State.IDLE
		State.BLOCK_START:
			if not animation_player.is_playing():
				return State.BLOCK
		State.BLOCK:
			if pending_counter_attack and state == State.BLOCK:
				return State.PARRY
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if not is_still:
				return State.RUNNING
			if block_timer.is_stopped() and not Input.is_action_pressed("block"):
				return State.IDLE
			if stats.energy <= 0.1:
				return State.IDLE#耐力耗尽强制退出
			if not animation_player.is_playing():
				return State.IDLE
		State.PARRY:
			if Input.is_action_just_pressed("block") and stats.energy > BLOCK_COST:
				stats.energy -= BLOCK_COST
				return State.BLOCK
			if not animation_player.is_playing():
				return State.IDLE
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
		State.SLIDING_START:
			if not animation_player.is_playing():
				return State.SLIDING_LOOP
		State.SLIDING_END:
			if not animation_player.is_playing():
				return State.IDLE
		State.SLIDING_LOOP:
			if state_machine.state_time > SLIDER_TIME or is_on_wall():
				return State.SLIDING_END
	return StateMachine.KEEP_CURRENT#state
	
func transition_state(from: State,to: State) ->void:
	print("[player %s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<State>",
		State.keys()[to],
	])
	if from not in GROUND_STATES and to in GROUND_STATES:#脱离地面状态
		coyote_timer.stop()
	
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUNNING:
			animation_player.play("running")
		State.CLIMBING:
			animation_player.play("climbing")
		State.JUMP:
			animation_player.play("jumping")
			if not is_floated:
				velocity.y = JUMP_VALOCTIY
			coyote_timer.stop()#郊狼时间
			jump_request_timer.stop()
			stats.energy -= JUMPING_COST
			SoundManager.play_sfx("jump")
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
			fall_form_y = global_position.y
		State.LANDING:
			animation_player.play("landing")
			Game.shack_camera(2)#震动
			SoundManager.play_sfx("landing")
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
		State.WALL_JUMP:
			animation_player.play("jumping")
			velocity = WALL_JUMP_VALOCTIY
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()
			stats.energy -= JUMPING_COST
			SoundManager.play_sfx("jump")
		State.BACK_JUMP:
			animation_player.play("back_jump")
			velocity = BACK_JUMP_VALOCTIY
			velocity.x *= direction
			stats.energy -= JUMPING_COST
			SoundManager.play_sfx("jump")
		State.BACK_JUMP_ATTACK:
			animation_player.play("back_jump_attack")
			stats.energy -= UP_ATTACK_COST
			SoundManager.play_sfx("jump")
		State.SPIKES:
			stats.energy -= UP_ATTACK_COST
			animation_player.play("spikes")
			is_combo_requested = false
			SoundManager.play_sfx("attack1")
		State.ATTACK_1:
			animation_player.play("attack_1")
			is_combo_requested = false
			SoundManager.play_sfx("attack1")
		State.ATTACK_2:
			animation_player.play("attack_2")
			is_combo_requested = false
			SoundManager.play_sfx("attack2")
		State.ATTACK_3:
			animation_player.play("attack_3")
			is_combo_requested = false
			SoundManager.play_sfx("attack3")
		State.AIR_ATTACK:
			animation_player.play("air_attack")
			is_floated = true
			is_combo_requested = false
			SoundManager.play_sfx("attack2")
		State.AIR_FALL_ATTACK:
			stats.energy -= UP_ATTACK_COST
			animation_player.play("air_fall_attack")
			is_combo_requested = false
			SoundManager.play_sfx("attack3")
		State.SPELL:
			animation_player.play("spells")
			stats.energy -= SPELLING_COST
			SoundManager.play_sfx("spells")
		State.BLOCK_START:
			animation_player.play("block_start")
			SoundManager.play_sfx("block_start")
		State.BLOCK:
			block_timer.start()#精防时间/最小防御时间
			animation_player.play("block")
		State.PARRY:
			pending_counter_attack = false
			block_timer.start()
			animation_player.play("parry")
		State.SLIDING_START:
			animation_player.play("sliding_start")
			slide_request_timer.stop()
			stats.energy -= SLIDING_COST
			SoundManager.play_sfx("sliding_start")
		State.SLIDING_LOOP:
			animation_player.play("sliding_loop")
		State.SLIDING_END:
			animation_player.play("sliding_end")
		State.HURT:
			animation_player.play("hurt")
			Game.shack_camera(3)
			stats.health -= pending_damage.amount
			var dir := pending_damage.source.global_position.direction_to(global_position)#来源指向自己
			velocity = dir * KNOCKBACK_AMOUNT
			
			invincible_timer.start()
			pending_damage = null
		State.DYING:
			invincible_timer.stop()
			animation_player.play("die")
			interacting_with.clear()#清空存储的交互
	#if to == State.WALL_JUMP:
		#Engine.time_scale = 0.3
	#if from == State.WALL_JUMP:
		#Engine.time_scale = 1.0
	
	is_first_tick = true #刚开始变化必定为第一帧

#注册可交互物体
func register_interactable(v: Interactable) ->void:
	if state_machine.current_state == State.DYING:#死亡状态不接收
		return
	if v in interacting_with:
		return
	interacting_with.append(v)

#卸载可交换物体
func unregister_interactable(v: Interactable) ->void:
	interacting_with.erase(v)#移除第一个匹配的值

#受到攻击
func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	if state_machine.current_state == State.BACK_JUMP and state_machine.state_time < 0.3:
		_on_dodge_successful()
		return
	if state_machine.current_state == State.BLOCK:
		if block_timer.time_left > 0:#精防
			execute_parry(hitbox.owner)#启用弹反
			return
		else:
			SoundManager.play_sfx("block")
			pending_damage = Damage.new()
			pending_damage.amount = 0.5
			pending_damage.source = hitbox.owner
	else:
		if invincible_timer.time_left > 0:#无敌帧
			return
		if state_machine.current_state == State.PARRY:#防反状态
			return
		pending_damage = Damage.new()
		pending_damage.amount = 1
		pending_damage.source = hitbox.owner

# 玩家脚本
func _on_dodge_successful():
	var miss_text = preload("res://Objects/text_tip.tscn").instantiate()
	
	# 设置显示位置（玩家当前位置）
	miss_text.position = global_position
	get_parent().add_child(miss_text)  # 添加到场景

func execute_parry(attacker: Node):
	stats.energy += BLOCK_COST+1
	# 1. 播放特效
	#$ParryParticles.emitting = true
	#$ParrySparkAnimation.play("spark")
	SoundManager.play_sfx("pro_block")
	# 2. 敌人硬直
	if attacker.has_method("stun"):#如果目标能够被眩晕
		attacker.stun(2.0)  #眩晕2秒
	#3. 玩家获得反击机会
	pending_counter_attack = true
	#4. 屏幕震动
	Game.shack_camera(1.5)
	#5. 慢动作特效
	pause_frame(0.3,0.1)

func die() ->void:
	game_over_screen.show_game_over()


func _on_hitbox_hit(hurtbox: Variant) -> void:
	Game.shack_camera(1)
	pause_frame(0.05,0.01)

func pause_frame(time: float,range:float) ->void:
	#顿帧
	Engine.time_scale = range
	await get_tree().create_timer(time,true,false,true).timeout
	#一次性计时器
	#如果 process_always 为 false，则暂停 SceneTree 也会暂停计时器。
	#如果 process_in_physics 为 true，则将在物理帧而不是处理帧期间更新 SceneTreeTimer（固定帧率处理）。
	#如果 ignore_time_scale 为 true，则将忽略 Engine.time_scale 并使用实际帧增量来更新 SceneTreeTimer。
	Engine.time_scale = 1

func bullet_creat() ->void:
	#print(get_tree().get_nodes_in_group("enemies"))
	for angle in [1,3,5,7]:
		var bullet_01 = bullet.instantiate()
		get_parent().add_child(bullet_01)
		bullet_01.position = lanch_point.global_position
		bullet_01.rotation = global_rotation + angle
