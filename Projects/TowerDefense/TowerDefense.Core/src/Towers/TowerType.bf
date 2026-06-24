using System;
namespace TowerDefense;

/// Tower weapon types.
public enum TowerType
{
	Ballista,
	Cannon,
	Catapult,
	Turret
}

/// Stats for a tower at a specific level.
public struct TowerLevelStats
{
	public float Damage;
	public float Range;
	public float FireRate;  // shots per second
	public int32 Cost;
	public int32 UpgradeCost;  // 0 = max level
}

/// Static data for each tower type.
public struct TowerStats
{
	public StringView BaseModel;
	public StringView WeaponModel;
	public StringView AmmoModel;
	public TowerLevelStats[3] Levels;

	public static TowerStats Get(TowerType type)
	{
		switch (type)
		{
		case .Ballista:
			return .()
			{
				BaseModel = "tower-round-base",
				WeaponModel = "weapon-ballista",
				AmmoModel = "weapon-ammo-arrow",
				Levels = .(
					.() { Damage = 20, Range = 3.5f, FireRate = 1.0f, Cost = 50, UpgradeCost = 75 },
					.() { Damage = 35, Range = 4.0f, FireRate = 1.2f, Cost = 0, UpgradeCost = 100 },
					.() { Damage = 55, Range = 4.5f, FireRate = 1.5f, Cost = 0, UpgradeCost = 0 }
				)
			};

		case .Cannon:
			return .()
			{
				BaseModel = "tower-square-bottom-a",
				WeaponModel = "weapon-cannon",
				AmmoModel = "weapon-ammo-cannonball",
				Levels = .(
					.() { Damage = 40, Range = 3.0f, FireRate = 0.5f, Cost = 75, UpgradeCost = 100 },
					.() { Damage = 70, Range = 3.5f, FireRate = 0.6f, Cost = 0, UpgradeCost = 125 },
					.() { Damage = 110, Range = 4.0f, FireRate = 0.7f, Cost = 0, UpgradeCost = 0 }
				)
			};

		case .Catapult:
			return .()
			{
				BaseModel = "tower-round-base",
				WeaponModel = "weapon-catapult",
				AmmoModel = "weapon-ammo-boulder",
				Levels = .(
					.() { Damage = 60, Range = 4.0f, FireRate = 0.3f, Cost = 60, UpgradeCost = 80 },
					.() { Damage = 100, Range = 4.5f, FireRate = 0.35f, Cost = 0, UpgradeCost = 110 },
					.() { Damage = 150, Range = 5.0f, FireRate = 0.4f, Cost = 0, UpgradeCost = 0 }
				)
			};

		case .Turret:
			return .()
			{
				BaseModel = "tower-square-bottom-a",
				WeaponModel = "weapon-turret",
				AmmoModel = "weapon-ammo-bullet",
				Levels = .(
					.() { Damage = 10, Range = 3.0f, FireRate = 4.0f, Cost = 100, UpgradeCost = 125 },
					.() { Damage = 15, Range = 3.5f, FireRate = 5.0f, Cost = 0, UpgradeCost = 150 },
					.() { Damage = 22, Range = 4.0f, FireRate = 6.0f, Cost = 0, UpgradeCost = 0 }
				)
			};
		}
	}
}
