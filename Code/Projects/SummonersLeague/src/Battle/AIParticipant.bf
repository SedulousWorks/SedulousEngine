namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// AI-controlled battle participant. Uses simple priority heuristics:
/// - Use strongest available damage ability
/// - Target lowest HP enemy
/// - Use heal if an ally is below 50% HP
/// - Fallback to basic attack
class AIParticipant : IBattleParticipant
{
	public BattleAction ChooseAction(MonsterInstance actor, BattleState state)
	{
		let allies = state.GetAlliedTeam(actor);
		let enemies = state.GetOpposingTeam(actor);

		// Check if any ally needs healing
		MonsterInstance woundedAlly = null;
		for (let ally in allies)
		{
			if (ally.IsAlive && ally.CurrentHP < ally.MaxHP / 2)
			{
				if (woundedAlly == null || ally.CurrentHP < woundedAlly.CurrentHP)
					woundedAlly = ally;
			}
		}

		// Find best ability to use
		int32 bestAbility = 0; // Default: basic attack (index 0)
		float bestScore = 0;
		bool isHealAction = false;

		if (actor.Def.Abilities != null)
		{
			for (int32 i = 0; i < (int32)actor.Def.Abilities.Count; i++)
			{
				if (!actor.CanUseAbility(i)) continue;

				let ability = actor.Def.Abilities[i];

				// Score healing abilities when allies are hurt
				if (ability.HealMultiplier > 0 && woundedAlly != null)
				{
					let score = ability.HealMultiplier * 10; // Prioritize healing
					if (score > bestScore)
					{
						bestScore = score;
						bestAbility = i;
						isHealAction = true;
					}
				}

				// Score damage abilities
				if (ability.DamageMultiplier > 0)
				{
					var score = ability.DamageMultiplier;
					// Bonus for status effects
					if (ability.StatusEffects != null && ability.StatusEffects.Count > 0)
						score += 0.5f;
					if (score > bestScore && !isHealAction)
					{
						bestScore = score;
						bestAbility = i;
					}
				}
			}
		}

		// Pick targets
		let ability = actor.Def.Abilities[bestAbility];
		MonsterInstance[] targets = null;

		switch (ability.Target)
		{
		case .SingleEnemy:
			let target = FindLowestHPAlive(enemies);
			if (target != null)
				targets = new .(target);

		case .AllEnemies:
			let aliveEnemies = scope List<MonsterInstance>();
			state.GetAlive(enemies, aliveEnemies);
			targets = new MonsterInstance[aliveEnemies.Count];
			for (let i < aliveEnemies.Count)
				targets[i] = aliveEnemies[i];

		case .SingleAlly:
			targets = new .((woundedAlly != null) ? woundedAlly : actor);

		case .AllAllies:
			let aliveAllies = scope List<MonsterInstance>();
			state.GetAlive(allies, aliveAllies);
			targets = new MonsterInstance[aliveAllies.Count];
			for (let i < aliveAllies.Count)
				targets[i] = aliveAllies[i];

		case .Self:
			targets = new .(actor);

		case .RandomEnemies:
			let aliveEnemies = scope List<MonsterInstance>();
			state.GetAlive(enemies, aliveEnemies);
			if (aliveEnemies.Count > 0)
			{
				let count = Math.Min(ability.HitCount, (int32)aliveEnemies.Count);
				targets = new MonsterInstance[count];
				for (let i < count)
					targets[i] = aliveEnemies[i % aliveEnemies.Count];
			}
		}

		if (targets == null)
			targets = new MonsterInstance[0];

		return .() { AbilityIndex = bestAbility, Targets = targets };
	}

	private MonsterInstance FindLowestHPAlive(List<MonsterInstance> team)
	{
		MonsterInstance lowest = null;
		for (let m in team)
		{
			if (!m.IsAlive) continue;
			if (lowest == null || m.CurrentHP < lowest.CurrentHP)
				lowest = m;
		}
		return lowest;
	}
}
