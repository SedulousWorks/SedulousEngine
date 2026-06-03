namespace SummonersLeague.Data;

/// Type effectiveness lookup table.
/// Returns the damage multiplier for an attack type hitting a defender type.
static class TypeChart
{
	public const float SuperEffective = 1.5f;
	public const float Resisted = 0.67f;
	public const float Normal = 1.0f;

	/// Returns the type multiplier for attackType vs defenderType.
	public static float GetMultiplier(ElementType attackType, ElementType defenderType)
	{
		// Neutral has no advantages or weaknesses
		if (attackType == .Neutral || defenderType == .Neutral)
			return Normal;

		// Elemental cycle: Fire -> Earth -> Electric -> Water -> Wind -> Fire
		switch (attackType)
		{
		case .Fire:
			if (defenderType == .Earth) return SuperEffective;
			if (defenderType == .Wind)  return Resisted;
		case .Earth:
			if (defenderType == .Electric) return SuperEffective;
			if (defenderType == .Fire)     return Resisted;
		case .Electric:
			if (defenderType == .Water)    return SuperEffective;
			if (defenderType == .Earth)    return Resisted;
		case .Water:
			if (defenderType == .Wind)     return SuperEffective;
			if (defenderType == .Electric) return Resisted;
		case .Wind:
			if (defenderType == .Fire)     return SuperEffective;
			if (defenderType == .Water)    return Resisted;

		// Dark <-> Light mutual
		case .Dark:
			if (defenderType == .Light) return SuperEffective;
		case .Light:
			if (defenderType == .Dark)  return SuperEffective;

		default:
		}

		return Normal;
	}

	/// Returns the multiplier for a dual-typed defender.
	/// Super-effective against both = 2.0x. SE + resisted cancel to 1.0x.
	public static float GetDualTypeMultiplier(ElementType attackType, ElementType defType1, ElementType defType2)
	{
		let m1 = GetMultiplier(attackType, defType1);
		let m2 = GetMultiplier(attackType, defType2);
		return m1 * m2;
	}
}
