extends Node2D
## First-pass Akteynt rig controller.
## The bone hierarchy is a rig scaffold; final separated character artwork must be
## attached to the bones before this can be considered production-ready.

@export var idle_breath := 0.035
@export var hair_sway := 0.09
@export var skirt_sway := 0.07

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var root_bone: Bone2D = $Skeleton2D/Root
@onready var torso: Bone2D = $Skeleton2D/Root/Torso
@onready var head: Bone2D = $Skeleton2D/Root/Torso/Head
@onready var hair_back: Bone2D = $Skeleton2D/Root/Torso/HairBack
@onready var arm_l: Bone2D = $Skeleton2D/Root/Torso/ArmL
@onready var arm_r: Bone2D = $Skeleton2D/Root/Torso/ArmR
@onready var skirt_l: Bone2D = $Skeleton2D/Root/Torso/SkirtL
@onready var skirt_r: Bone2D = $Skeleton2D/Root/Torso/SkirtR
@onready var leg_l: Bone2D = $Skeleton2D/Root/Torso/LegL
@onready var leg_r: Bone2D = $Skeleton2D/Root/Torso/LegR
@onready var weapon: Bone2D = $Skeleton2D/Root/Torso/ArmR/Weapon

var elapsed := 0.0
var pose := "idle"
var pose_time := 0.0
var attack_direction := 1.0

func set_pose(next_pose: String, direction: float = 1.0) -> void:
	pose = next_pose
	pose_time = 0.0
	attack_direction = signf(direction) if not is_zero_approx(direction) else 1.0

func _process(delta: float) -> void:
	elapsed += delta
	pose_time += delta
	var breath := sin(elapsed * 2.1) * idle_breath
	var hair := sin(elapsed * 1.8) * hair_sway
	var skirt := sin(elapsed * 2.6) * skirt_sway
	root_bone.rotation = 0.0
	torso.rotation = breath
	head.rotation = -breath * 0.45
	hair_back.rotation = hair
	skirt_l.rotation = skirt
	skirt_r.rotation = -skirt
	arm_l.rotation = -0.08 + breath
	arm_r.rotation = 0.08 - breath
	leg_l.rotation = 0.0
	leg_r.rotation = 0.0
	weapon.rotation = 0.0
	match pose:
		"run":
			var step := sin(pose_time * 12.0)
			leg_l.rotation = step * 0.48
			leg_r.rotation = -step * 0.48
			arm_l.rotation = -step * 0.32
			arm_r.rotation = step * 0.32
			hair_back.rotation += sin(pose_time * 12.0) * 0.12
			skirt_l.rotation += step * 0.1
			skirt_r.rotation -= step * 0.1
		"dash":
			root_bone.rotation = -0.16 * attack_direction
			torso.rotation = 0.24 * attack_direction
			hair_back.rotation = -0.38 * attack_direction
			skirt_l.rotation = -0.2 * attack_direction
			skirt_r.rotation = -0.12 * attack_direction
		"attack":
			var swing := sin(minf(pose_time / 0.24, 1.0) * PI)
			arm_r.rotation = -1.05 * attack_direction * swing
			weapon.rotation = 1.4 * attack_direction * swing
			torso.rotation = 0.22 * attack_direction * swing
			hair_back.rotation = -0.16 * attack_direction * swing
		"finisher":
			var impact := sin(minf(pose_time / 0.42, 1.0) * PI)
			root_bone.rotation = -0.12 * attack_direction * impact
			torso.rotation = 0.5 * attack_direction * impact
			arm_r.rotation = -1.55 * attack_direction * impact
			weapon.rotation = 1.9 * attack_direction * impact
			skirt_l.rotation = -0.18 * impact
			skirt_r.rotation = 0.18 * impact
		"hurt":
			var recoil := 1.0 - minf(pose_time / 0.2, 1.0)
			root_bone.rotation = -0.24 * attack_direction * recoil
			torso.rotation = -0.28 * attack_direction * recoil
			head.rotation = 0.22 * attack_direction * recoil
		"victory":
			torso.rotation = -0.12 + breath
			arm_l.rotation = -0.38 + breath
			arm_r.rotation = 0.38 - breath
