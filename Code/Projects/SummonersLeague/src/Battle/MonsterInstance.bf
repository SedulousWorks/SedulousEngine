namespace SummonersLeague.Battle;

using System;
using System.Collections;
using SummonersLeague.Data;

/// A monster participating in battle. Holds runtime state: current HP,
/// active status effects, ability cooldowns, turn bar progress.
/// References a MonsterDef (immutable template) + a level.
class MonsterInstance
{
	/// The template definition for this monster species.
	public MonsterDef Def;

	/// Current level (affects stat scaling).
	public int32 Level;

	/// Team index (0 = team A, 1 = team B). Set by BattleState.
	public int32 TeamIndex;

	/// Slot index within the team (0-3).
	public int32 SlotIndex;

	// --- Runtime battle state ---

	/// Current hit points. 0 = knocked out.
	public int32 CurrentHP;

	/// Maximum HP (computed from base + level + items).
	public int32 MaxHP;

	/// Turn bar value (0-100). Monster acts when this reaches 100.
	public float TurnBar;

	/// Active status effects.
	public List<StatusEffect> StatusEffects = new .() ~ delete _;

	/// Ability cooldowns (remaining turns). Indexed same as Def.Abilities.
	public int32[] Cooldowns ~ delete _;

	/// Whether this monster has used its Last Stand Amulet this battle.
	public bool LastStandUsed;

	// --- Stat growth ---

	private const float GrowthRate = 0.05f;

	/// Initialize for battle from a definition and level.
	public void Initialize(MonsterDef def, int32 level)
	{
		Def = def;
		Level = level;
		TurnBar = 0;
		LastStandUsed = false;

		MaxHP = ScaleStat(def.Stats.HP);
		CurrentHP = MaxHP;

		StatusEffects.Clear();

		// Initialize cooldowns (all abilities start ready)
		if (Cooldowns != null) delete Cooldowns;
		if (def.Abilities != null)
		{
			Cooldowns = new int32[def.Abilities.Count];
			for (int i = 0; i < Cooldowns.Count; i++)
				Cooldowns[i] = 0;
		}
	}

	/// Whether this monster is still alive.
	public bool IsAlive => CurrentHP > 0;

	/// Computed ATK after level scaling and status modifiers.
	public int32 ATK
	{
		get
		{
			var atk = (float)ScaleStat(Def.Stats.ATK);
			atk *= GetStatusMultiplier(.AtkBreak);
			return Math.Max((int32)atk, 1);
		}
	}

	/// Computed DEF after level scaling and status modifiers.
	public int32 DEF
	{
		get
		{
			var def = (float)ScaleStat(Def.Stats.DEF);
			def *= GetStatusMultiplier(.DefBreak);
			return Math.Max((int32)def, 1);
		}
	}

	/// Computed SPD after level scaling and status modifiers.
	public int32 SPD
	{
		get
		{
			var spd = (float)ScaleStat(Def.Stats.SPD);
			spd *= GetStatusMultiplier(.SpeedUp);
			spd *= GetStatusMultiplier(.SpeedDown);
			return Math.Max((int32)spd, 1);
		}
	}

	/// Scale a base stat by level.
	private int32 ScaleStat(int32 baseStat)
	{
		return (int32)(baseStat + baseStat * (Level - 1) * GrowthRate);
	}

	/// Get the stat multiplier from a specific status effect type.
	private float GetStatusMultiplier(StatusEffectType type)
	{
		for (let effect in StatusEffects)
		{
			if (effect.Type == type)
				return 1.0f - effect.Value; // Value is the reduction/boost amount
		}
		return 1.0f;
	}

	/// Whether this monster has a specific status effect active.
	public bool HasStatus(StatusEffectType type)
	{
		for (let effect in StatusEffects)
			if (effect.Type == type) return true;
		return false;
	}

	/// Whether this monster is stunned or frozen (can't act this turn).
	public bool IsIncapacitated => HasStatus(.Stun) || HasStatus(.Freeze);

	/// Whether this monster has Immunity (debuffs are blocked).
	public bool HasImmunity => HasStatus(.Immunity);

	/// Check if an ability is available (not on cooldown, level requirement met).
	public bool CanUseAbility(int32 abilityIndex)
	{
		if (Def.Abilities == null || abilityIndex >= Def.Abilities.Count)
			return false;
		if (Cooldowns != null && abilityIndex < Cooldowns.Count && Cooldowns[abilityIndex] > 0)
			return false;
		if (Def.Abilities[abilityIndex].UnlockLevel > Level)
			return false;
		return true;
	}

	/// Take damage. Returns actual damage dealt after shields/fatal-hit survival.
	public int32 TakeDamage(int32 rawDamage)
	{
		var damage = rawDamage;

		// Shield absorbs damage first
		for (var effect in ref StatusEffects)
		{
			if (effect.Type == .Shield && effect.Value > 0)
			{
				let absorbed = Math.Min(damage, (int32)effect.Value);
				effect.Value -= absorbed;
				damage -= absorbed;
				if (damage <= 0) return rawDamage - damage;
			}
		}

		CurrentHP -= damage;

		// Last Stand Amulet: survive fatal hit with 1 HP
		if (CurrentHP <= 0 && !LastStandUsed)
		{
			// TODO: check equipped items for LastStandAmulet
			// For now, this is a placeholder
		}

		CurrentHP = Math.Max(CurrentHP, 0);
		return damage;
	}

	/// Heal this monster. Returns actual HP restored.
	public int32 Heal(int32 amount)
	{
		let before = CurrentHP;
		CurrentHP = Math.Min(CurrentHP + amount, MaxHP);
		return CurrentHP - before;
	}

	/// Tick ability cooldowns (called at end of this monster's turn).
	public void TickCooldowns()
	{
		if (Cooldowns == null) return;
		for (int i = 0; i < Cooldowns.Count; i++)
			if (Cooldowns[i] > 0)
				Cooldowns[i]--;
	}

	/// Set an ability on cooldown after use.
	public void SetCooldown(int32 abilityIndex, int32 turns)
	{
		if (Cooldowns != null && abilityIndex < Cooldowns.Count)
			Cooldowns[abilityIndex] = turns;
	}
}
