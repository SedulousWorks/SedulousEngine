namespace SummonersLeague.Data;

using System;

/// Base stats for a monster at level 1. Stats scale with level.
struct BaseStats
{
	public int32 HP;
	public int32 ATK;
	public int32 DEF;
	public int32 SPD;
}

/// Definition of a monster species. Immutable template data.
/// A player's owned monster is a MonsterInstance that references a MonsterDef.
class MonsterDef
{
	/// Unique identifier (e.g., "seed", "dragon_spark").
	public StringView Id;

	/// Display name (e.g., "Seed", "Dragon Spark").
	public StringView Name;

	/// Elemental type.
	public ElementType Element;

	/// Rarity tier.
	public Rarity Rarity;

	/// Base stats at level 1.
	public BaseStats Stats;

	/// Abilities this monster can learn. Ordered: [0] = basic attack,
	/// [1] = ability 1, [2] = ability 2. Unlock level set per ability.
	public AbilityDef[] Abilities ~ delete _;

	/// Passive ability (always active). Null if none.
	public AbilityDef Passive;

	/// Id of the monster this evolves into. Null if final form.
	public StringView EvolvesInto;

	/// Asset path for the 3D model (CuteSeries prefab name).
	public StringView ModelAsset;

	/// Brief description for UI / collection screen.
	public StringView Description;
}
