namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// Result of a single hit within a turn.
struct HitResult
{
	public MonsterInstance Target;
	public int32 Damage;
	public int32 Healed;
	public bool WasCrit;
	public bool WasDodged;
	public float TypeMultiplier;
	public StatusEffectType AppliedStatus;
	public bool StatusLanded;
	public bool TargetKO;
}

/// What happened during one monster's turn.
class TurnResult
{
	/// The monster that acted.
	public MonsterInstance Actor;

	/// The ability used.
	public AbilityDef Ability;

	/// Whether the actor was incapacitated (stun/freeze) and skipped.
	public bool WasStunned;

	/// Whether the actor died from DoT before acting.
	public bool DiedFromDoT;

	/// Status effect tick results (DoT damage, heals) at start of turn.
	public List<(StatusEffectType Type, int32 Value)> StatusTicks = new .() ~ delete _;

	/// Results for each target hit.
	public List<HitResult> Hits = new .() ~ delete _;

	/// Turn number within the battle.
	public int32 TurnNumber;
}
