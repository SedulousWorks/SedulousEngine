namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// Resolves an ability use: damage, healing, status effects.
static class AbilityExecutor
{
	/// Execute an ability. Returns a TurnResult describing what happened.
	public static TurnResult Execute(MonsterInstance actor, int32 abilityIndex,
		MonsterInstance[] targets, BattleState state)
	{
		let result = new TurnResult();
		result.Actor = actor;
		result.TurnNumber = state.TurnNumber;

		let ability = actor.Def.Abilities[abilityIndex];
		result.Ability = ability;

		// Tick status effects at the start of this monster's turn
		StatusEffectSystem.TickEffects(actor, result.StatusTicks);

		// Check if actor died from DoT during status tick
		if (!actor.IsAlive)
		{
			result.DiedFromDoT = true;
			return result;
		}

		// Check if incapacitated (stun/freeze)
		if (actor.IsIncapacitated)
		{
			result.WasStunned = true;
			// Remove the stun/freeze (it consumed the skip)
			for (int i = actor.StatusEffects.Count - 1; i >= 0; i--)
			{
				let effect = actor.StatusEffects[i];
				if (effect.Type == .Stun || effect.Type == .Freeze)
				{
					actor.StatusEffects.RemoveAt(i);
					break; // Only remove one
				}
			}
			actor.TickCooldowns();
			return result;
		}

		// Execute ability on each target
		for (let target in targets)
		{
			if (!target.IsAlive) continue;

			HitResult hit = .();
			hit.Target = target;

			// Damage
			if (ability.DamageMultiplier > 0)
			{
				let dmgResult = DamageCalc.Calculate(actor, target, ability);
				hit.WasCrit = dmgResult.WasCrit;
				hit.WasDodged = dmgResult.WasDodged;
				hit.TypeMultiplier = dmgResult.TypeMultiplier;

				if (!dmgResult.WasDodged)
				{
					hit.Damage = target.TakeDamage(dmgResult.Damage);
					hit.TargetKO = !target.IsAlive;
				}
			}

			// Healing
			if (ability.HealMultiplier > 0)
			{
				let healAmount = DamageCalc.CalculateHeal(actor, ability);
				hit.Healed = target.Heal(healAmount);
			}

			// Status effects
			if (ability.StatusEffects != null && !hit.WasDodged)
			{
				for (let statusDef in ability.StatusEffects)
				{
					let landed = StatusEffectSystem.ApplyEffect(
						target, statusDef.Effect, statusDef.Duration, statusDef.Value, statusDef.Chance);
					if (landed)
					{
						hit.AppliedStatus = statusDef.Effect;
						hit.StatusLanded = true;
					}
				}
			}

			result.Hits.Add(hit);
		}

		// Set cooldown
		if (ability.Cooldown > 0)
			actor.SetCooldown(abilityIndex, ability.Cooldown);

		// Tick cooldowns
		actor.TickCooldowns();

		return result;
	}
}
