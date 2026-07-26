extends RefCounted
class_name BattleFSM
# Battle phase state machine (ADR-002 / E3-B). Phases drive the turn loop; UI-only
# EventBus signals are emitted on transitions (no logic mutation here). Sprint 1: phase
# enum + transition guards (structure); real UI wiring lands in Sprint 2.

enum Phase { PreBattle, PlayerInput, Resolve, CheckEnd, Victory, Defeat }

var phase: int = Phase.PreBattle

func can_transition(from: int, to: int) -> bool:
	match from:
		Phase.PreBattle:
			return to == Phase.PlayerInput
		Phase.PlayerInput:
			return to == Phase.Resolve
		Phase.Resolve:
			return to == Phase.CheckEnd
		Phase.CheckEnd:
			return to == Phase.PlayerInput or to == Phase.Victory or to == Phase.Defeat
		Phase.Victory, Phase.Defeat:
			return false
	return false

func transition(to: int) -> bool:
	if can_transition(phase, to):
		phase = to
		return true
	return false

func is_over() -> bool:
	return phase == Phase.Victory or phase == Phase.Defeat
