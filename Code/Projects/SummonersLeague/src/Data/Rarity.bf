namespace SummonersLeague.Data;

/// Monster rarity tier. Affects base stat totals, level cap, and summon rates.
enum Rarity : uint8
{
	case Common;     // 1-star
	case Uncommon;   // 2-star
	case Rare;       // 3-star
	case Epic;       // 4-star
	case Legendary;  // 5-star

	/// Star count for display (1-5).
	public int Stars
	{
		get
		{
			switch (this)
			{
			case .Common:    return 1;
			case .Uncommon:  return 2;
			case .Rare:      return 3;
			case .Epic:      return 4;
			case .Legendary: return 5;
			}
		}
	}

	/// Max level for this rarity tier.
	public int MaxLevel
	{
		get
		{
			switch (this)
			{
			case .Common:    return 20;
			case .Uncommon:  return 25;
			case .Rare:      return 30;
			case .Epic:      return 40;
			case .Legendary: return 50;
			}
		}
	}
}
