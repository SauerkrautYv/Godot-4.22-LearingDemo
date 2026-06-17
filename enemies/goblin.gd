extends Enemy

enum State{
	IDLE,
	WALK,
	RUN,
	ATTACK,
	HURT,
	DYING,
	STUN,
}

var pending_damage:Damage

const KNOCKBACK_AMOUNT := 240.0#击退
@onready var walk_checker: RayCast2D = $Graphics/WalkChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var attack_checker: RayCast2D = $Graphics/AttackChecker
@onready var wall_checker: RayCast2D = $Graphics/WallChecker

@onready var stun_timer: Timer = $StunTimer
@onready var calm_down_timer: Timer = $CalmDownTimer

@onready var dameged_audio: AudioStreamPlayer2D = $DamegedAudio
@onready var stun_icon: AnimatedSprite2D = $StunIcon

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
	match state:
		State.IDLE:
			move(0.0,delte)
		State.ATTACK:
			move(0.0,delte)
		State.STUN:
			move(0.0,delte)
		State.WALK:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				direction *= -1
			move(max_speed/3,delte)
		State.RUN:
			get_direction_toward_player()
			move(max_speed,delte)
			if can_see_player():
				calm_down_timer.start()
		State.DYING,State.HURT:
			move(0.0,delte)

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
	if stun_timer.time_left > 0 and state !=State.HURT:
		if state !=State.STUN:
			return State.STUN
		else:
			return StateMachine.KEEP_CURRENT
	match state:
		State.IDLE:
			if can_see_player() and floor_checker.is_colliding():
				return State.RUN
			if state_machine.state_time > 2:
				return State.WALK
		State.WALK:
			if can_see_player() and floor_checker.is_colliding():
				return State.RUN
			if not floor_checker.is_colliding():
				return State.IDLE
		State.RUN:
			if attack_checker.is_colliding():
				return State.ATTACK
			if not can_see_player() and calm_down_timer.is_stopped():
				return State.WALK
		State.HURT:
			if not animation_player.is_playing():
				if stun_timer.time_left > 0:
					return State.STUN
				return State.RUN
		State.STUN:
			if stun_timer.is_stopped():
				return State.IDLE
			if not animation_player.is_playing():
				return State.IDLE
		State.ATTACK:
			if not animation_player.is_playing():
				return State.RUN
	return StateMachine.KEEP_CURRENT#state#

func transition_state(from: State,to: State) ->void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<State>",
		#State.keys()[to],
	#])

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
		State.HURT:
			animation_player.play("hit")
		State.STUN:
			animation_player.play("stun")
		State.ATTACK:
			animation_player.play("attack")
		State.DYING:
			animation_player.play("die")

func stun(duration: float):
	stun_timer.start(duration)

func _on_hurtbox_hurt(hitbox: Variant)-> void:
	pending_damage = Damage.new()
	pending_damage.amount = 1
	pending_damage.source = hitbox.owner
