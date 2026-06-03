namespace SummonersLeague.Data;

using System;

/// Item slot category. Matching item category to slot type grants a bonus.
enum ItemCategory : uint8
{
	Power,
	Agility,
	Accuracy,
	Resistance
}

/// Item quality tier. Higher tiers scale the bonus values.
enum ItemTier : uint8
{
	Normal,    // base values
	Enhanced,  // +50% effect
	Superior   // +100% effect
}

/// Definition of an equippable item. Immutable template data.
class ItemDef
{
	/// Unique identifier.
	public StringView Id;

	/// Display name.
	public StringView Name;

	/// Slot category this item belongs to.
	public ItemCategory Category;

	/// Brief description of the effect.
	public StringView Description;

	/// Flat stat bonuses (added to monster stats when equipped).
	/// Expressed as percentages (0.15 = +15%).
	public float AtkBonus;
	public float DefBonus;
	public float SpdBonus;
	public float HpBonus;

	/// Special effect flags (for items with unique mechanics).
	public float DamageBonus;       // +X% damage dealt (e.g., Blood Shard)
	public float HpCostPerAttack;   // lose X% HP per attack (e.g., Blood Shard)
	public float DodgeChance;       // +X% dodge chance
	public float HitRateBonus;      // +X% accuracy
	public float DebuffLandRate;    // +X% debuff application rate
	public float DebuffResist;      // +X% debuff resist
	public float HealPerTurn;       // heal X% HP at end of turn
	public bool SurviveFatalHit;    // survive one fatal hit with 1 HP
}
