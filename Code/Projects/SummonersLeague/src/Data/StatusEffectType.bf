namespace SummonersLeague.Data;

/// Status effect that can be applied to a monster during battle.
enum StatusEffectType : uint8
{
	/// X% max HP damage per turn, does not stack (refreshes duration).
	Poison,
	/// Damage over time + reduces ATK.
	Burn,
	/// Skip next turn.
	Stun,
	/// Skip next turn + take extra damage when hit.
	Freeze,
	/// Reduce DEF for N turns.
	DefBreak,
	/// Reduce ATK for N turns.
	AtkBreak,
	/// Increase SPD for N turns.
	SpeedUp,
	/// Decrease SPD for N turns.
	SpeedDown,
	/// Absorbs X damage before HP is affected.
	Shield,
	/// Prevents debuffs for N turns.
	Immunity,
	/// Heal X% HP per turn.
	ContinuousHeal
}
