extends Enemy

enum State{
	IDLE,
	FLIGHT,
	FLIGHT_RUN,
	ATTACK,
	HURT,
	DYING,
}
var pending_damage:Damage
var player_in_sight:=false
const KNOCKBACK_AMOUNT := 240.0#击退
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer
@onready var dameged_audio: AudioStreamPlayer2D = $DamegedAudio
@onready var attack_checker: RayCast2D = $Graphics/AttackChecker
@onready var walk_checker: RayCast2D = $Graphics/WalkChecker

func can_see_player() -> bool:
	if walk_checker.is_colliding():
		return false
	return player_in_sight

func get_direction_toward_player() -> void:
	var player = get_node("../player")
	if player.global_position.x < global_position.x +15:
		direction = Direction.LEFT  # 向左移动
	elif player.global_position.x > global_position.x -15:
		direction = Direction.RIGHT   # 向右移动
	else:
		direction = direction   # 不需要水平移动

func get_vertical_direction_toward_player() -> int:
	var player = get_node("../player")
	if player.global_position.y < global_position.y +35:
		return -1  # 向上移动
	elif player.global_position.y > global_position.y +25:
		return 1   # 向下移动
	else:
		return 0   # 不需要垂直移动

func tick_physics(state:State ,delte:float) -> void:
	match state:
		State.IDLE:
			move(0.0,delte,true)
		State.ATTACK:
			move(0.0,delte,true)
		State.FLIGHT:
			move(max_speed/3,delte,true,get_vertical_direction_toward_player())
		State.FLIGHT_RUN:
			if floor_checker.is_colliding():
				direction *= -1
			get_direction_toward_player()
			move(max_speed,delte,true,get_vertical_direction_toward_player())
			if can_see_player():
				calm_down_timer.start()
		State.DYING,State.HURT:
			move(0.0,delte,true)

func get_next_state(state:State) -> int:
	if stats.health <= 0:
		return StateMachine.KEEP_CURRENT if state == State.DYING else State.DYING#State.DYING
	if pending_damage:
		dameged_audio.play()
		stats.health -= pending_damage.amount
		var dir := pending_damage.source.global_position.direction_to(global_position)#来源指向自己
		velocity = dir * KNOCKBACK_AMOUNT
		if dir.x>0:
			direction = Direction.LEFT
		else:
			direction = Direction.RIGHT
		pending_damage = null
		return State.HURT
	
	match state:
		State.IDLE:
			if can_see_player() and not floor_checker.is_colliding():
				return State.FLIGHT_RUN
			if state_machine.state_time > 2:
				return State.FLIGHT
		State.FLIGHT:
			if can_see_player() and not floor_checker.is_colliding():
				return State.FLIGHT_RUN
			if not floor_checker.is_colliding():
				return State.IDLE
		State.FLIGHT_RUN:
			if attack_checker.is_colliding():
				return State.ATTACK
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.FLIGHT
		State.HURT:
			if not animation_player.is_playing():
				return State.FLIGHT_RUN
		State.ATTACK:
			if not animation_player.is_playing():
				return State.FLIGHT_RUN
	return StateMachine.KEEP_CURRENT#state#

func transition_state(from: State,to: State) ->void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<State>",
		#State.keys()[to],
	#])

	match to:
		State.IDLE:
			animation_player.play("flighting")
			if floor_checker.is_colliding():
				direction *= -1
				#floor_checker.force_raycast_update()
		State.FLIGHT:
			animation_player.play("flighting")
			if floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update()
		State.FLIGHT_RUN:
			animation_player.play("flighting")
		State.HURT:
			animation_player.play("hit")
		State.ATTACK:
			animation_player.play("attack")
		State.DYING:
			animation_player.play("die")

func _on_hurtbox_hurt(hitbox: Variant) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner


func _on_player_cheacker_body_entered(body: Node2D) -> void:
	player_in_sight = true


func _on_player_cheacker_body_exited(body: Node2D) -> void:
	player_in_sight = false
