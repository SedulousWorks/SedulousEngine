namespace SummonersLeague.Data;

/// How an ability selects its target(s).
enum TargetMode : uint8
{
	/// Player picks one enemy.
	SingleEnemy,
	/// Hits all enemies.
	AllEnemies,
	/// Hits random enemies (count specified by ability).
	RandomEnemies,
	/// Player picks one ally.
	SingleAlly,
	/// Affects all allies.
	AllAllies,
	/// Affects self only.
	Self
}
