namespace SummonersLeague.Data;

using System;

/// Defines a status effect application on an ability.
struct AbilityStatusEffect
{
	public StatusEffectType Effect;
	public int32 Duration;     // turns
	public float Chance;       // 0.0 - 1.0 probability of applying
	public float Value;        // effect-specific: damage %, heal %, stat modifier %
}

/// Definition of a monster ability. Immutable template data.
class AbilityDef
{
	/// Unique identifier.
	public StringView Id;

	/// Display name.
	public StringView Name;

	/// Element type of this ability (determines type matchup damage).
	public ElementType Element;

	/// How the ability selects targets.
	public TargetMode Target;

	/// Damage multiplier applied to ATK. 0 = non-damaging ability.
	public float DamageMultiplier;

	/// Heal multiplier applied to ATK. 0 = non-healing ability.
	public float HealMultiplier;

	/// Number of hits (for RandomEnemies target mode).
	public int32 HitCount = 1;

	/// Cooldown in turns after use. 0 = no cooldown.
	public int32 Cooldown;

	/// Status effects applied on hit.
	public AbilityStatusEffect[] StatusEffects ~ delete _;

	/// Level at which this ability is unlocked. 0 = available immediately.
	public int32 UnlockLevel;

	/// Brief description for UI.
	public StringView Description;
}
