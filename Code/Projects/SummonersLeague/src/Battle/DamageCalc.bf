namespace SummonersLeague.Battle;

using System;
using SummonersLeague.Data;

/// Result of a damage calculation.
struct DamageResult
{
	public int32 Damage;
	public bool WasCrit;
	public bool WasDodged;
	public float TypeMultiplier;
}

/// Static utility for the damage formula.
static class DamageCalc
{
	public const float CritChance = 0.15f;
	public const float CritMultiplier = 1.5f;
	public const float VarianceMin = 0.9f;
	public const float VarianceMax = 1.1f;

	private static Random sRandom = new .() ~ delete _;

	/// Calculate damage for an ability hit.
	public static DamageResult Calculate(MonsterInstance attacker, MonsterInstance defender, AbilityDef ability)
	{
		DamageResult result = .();

		// Dodge check (placeholder — items will add dodge chance)
		// TODO: check defender's equipped items for dodge chance
		result.WasDodged = false;
		if (result.WasDodged)
			return result;

		// Base damage formula (inspired by Pokemon):
		// ((2 * Level / 5 + 2) * ATK * AbilityMultiplier / DEF) / 50 + 2
		// At level 10 with ATK=26, DEF=13, mult=1.0: ((4+2)*26*1.0/13)/50+2 = 12/50+2 ≈ 2.24
		// With mult=2.0 (Fireball): ≈ 4.48
		// This gives meaningful damage while keeping fights ~10-20 turns.
		// Targets ~25-35% of defender's HP per basic attack, ~50-70% for specials.
		// Battles should resolve in ~8-15 turns for a 3v3.
		let levelFactor = (2.0f * attacker.Level / 5.0f + 2.0f);
		float baseDamage = (levelFactor * attacker.ATK * ability.DamageMultiplier / (float)defender.DEF) + 2;

		// Type effectiveness
		result.TypeMultiplier = TypeChart.GetMultiplier(ability.Element, defender.Def.Element);
		baseDamage *= result.TypeMultiplier;

		// Crit check
		result.WasCrit = sRandom.NextDouble() < CritChance;
		if (result.WasCrit)
			baseDamage *= CritMultiplier;

		// Random variance
		let variance = VarianceMin + (float)sRandom.NextDouble() * (VarianceMax - VarianceMin);
		baseDamage *= variance;

		// Freeze: extra damage on frozen targets
		if (defender.HasStatus(.Freeze))
			baseDamage *= 1.25f;

		result.Damage = Math.Max((int32)baseDamage, 1);
		return result;
	}

	/// Calculate healing amount.
	public static int32 CalculateHeal(MonsterInstance healer, AbilityDef ability)
	{
		return Math.Max((int32)(healer.ATK * ability.HealMultiplier), 1);
	}
}
