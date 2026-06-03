namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// Manages status effects on monsters during battle.
static class StatusEffectSystem
{
	/// Apply a status effect to a monster. Returns true if it landed.
	/// Respects Immunity (blocks debuffs) and no-stack rules (Poison refreshes).
	public static bool ApplyEffect(MonsterInstance target, StatusEffectType type, int32 duration, float value, float chance)
	{
		// Random chance check
		if (chance < 1.0f)
		{
			let roll = DamageCalc.[Friend]sRandom.NextDouble();
			if (roll >= chance)
				return false;
		}

		let effect = StatusEffect() { Type = type, RemainingTurns = duration, Value = value };

		// Debuffs blocked by Immunity
		if (effect.IsDebuff && target.HasImmunity)
			return false;

		// Non-stacking effects: refresh duration if already present
		for (var existing in ref target.StatusEffects)
		{
			if (existing.Type == type)
			{
				existing.RemainingTurns = Math.Max(existing.RemainingTurns, duration);
				existing.Value = Math.Max(existing.Value, value);
				return true;
			}
		}

		target.StatusEffects.Add(effect);
		return true;
	}

	/// Tick status effects at the start of a monster's turn.
	/// Returns a list of (effect type, value) for logging.
	public static void TickEffects(MonsterInstance monster, List<(StatusEffectType Type, int32 Value)> ticks)
	{
		ticks.Clear();

		for (int i = monster.StatusEffects.Count - 1; i >= 0; i--)
		{
			var effect = ref monster.StatusEffects[i];

			switch (effect.Type)
			{
			case .Poison:
				let damage = Math.Max((int32)(monster.MaxHP * effect.Value), 1);
				monster.CurrentHP = Math.Max(monster.CurrentHP - damage, 0);
				ticks.Add((.Poison, damage));

			case .Burn:
				let damage = Math.Max((int32)(monster.MaxHP * effect.Value), 1);
				monster.CurrentHP = Math.Max(monster.CurrentHP - damage, 0);
				ticks.Add((.Burn, damage));

			case .ContinuousHeal:
				let heal = Math.Max((int32)(monster.MaxHP * effect.Value), 1);
				let healed = monster.Heal(heal);
				if (healed > 0) ticks.Add((.ContinuousHeal, healed));

			case .Shield:
				// Shield doesn't tick — it absorbs damage in TakeDamage()
				break;

			default:
				// Stun, Freeze, DefBreak, AtkBreak, SpeedUp/Down, Immunity
				// These are checked passively — just need to decrement duration
				break;
			}

			// Decrement duration
			effect.RemainingTurns--;
			monster.StatusEffects[i] = effect;

			if (effect.RemainingTurns <= 0)
				monster.StatusEffects.RemoveAt(i);
		}
	}
}
