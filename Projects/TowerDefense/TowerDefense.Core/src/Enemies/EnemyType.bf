using System;
namespace TowerDefense;

/// Enemy variant types, each with different stats.
public enum EnemyType
{
	UfoA,
	UfoB,
	UfoC,
	UfoD
}

/// Static stats for each enemy type.
public struct EnemyStats
{
	public float Health;
	public float Speed;
	public int32 Reward;
	public StringView ModelName;

	public static EnemyStats Get(EnemyType type)
	{
		switch (type)
		{
		case .UfoA: return .() { Health = 80,  Speed = 1.8f, Reward = 10, ModelName = "enemy-ufo-a" };
		case .UfoB: return .() { Health = 150, Speed = 1.4f, Reward = 15, ModelName = "enemy-ufo-b" };
		case .UfoC: return .() { Health = 250, Speed = 1.1f, Reward = 25, ModelName = "enemy-ufo-c" };
		case .UfoD: return .() { Health = 400, Speed = 0.9f, Reward = 40, ModelName = "enemy-ufo-d" };
		}
	}
}
