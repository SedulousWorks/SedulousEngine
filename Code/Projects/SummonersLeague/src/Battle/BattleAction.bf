namespace SummonersLeague.Battle;

using System.Collections;
using SummonersLeague.Data;

/// An action chosen by a participant: which ability to use and on which targets.
struct BattleAction
{
	/// Index into the actor's Def.Abilities array.
	public int32 AbilityIndex;

	/// Target monster instances. Single-target abilities have 1 entry,
	/// AoE fills all valid targets, self-target uses the actor.
	public MonsterInstance[] Targets;
}
