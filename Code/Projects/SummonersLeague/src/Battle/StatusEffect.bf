namespace SummonersLeague.Battle;

using SummonersLeague.Data;

/// An active status effect on a monster during battle.
struct StatusEffect
{
	/// Which status effect.
	public StatusEffectType Type;

	/// Remaining turns before expiry.
	public int32 RemainingTurns;

	/// Effect-specific value (DoT %, stat modifier %, shield HP, etc.).
	public float Value;

	/// Whether this effect is a debuff (can be blocked by Immunity).
	public bool IsDebuff
	{
		get
		{
			switch (Type)
			{
			case .Poison, .Burn, .Stun, .Freeze, .DefBreak, .AtkBreak, .SpeedDown:
				return true;
			default:
				return false;
			}
		}
	}
}
