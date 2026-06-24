namespace TowerDefense;

using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.Messaging;

// All game message types. Structs implementing IMessage for the MessageBus.

struct EnemyKilledMsg : IMessage
{
	public EntityHandle EntityId;
	public int32 Reward;
	public Vector3 Position;
	public void Dispose() mut { }
}

struct EnemyReachedEndMsg : IMessage
{
	public EntityHandle EntityId;
	public int32 LivesLost;
	public void Dispose() mut { }
}

struct WaveStartedMsg : IMessage
{
	public int32 WaveNumber;
	public void Dispose() mut { }
}

struct WaveCompletedMsg : IMessage
{
	public int32 WaveNumber;
	public int32 BonusGold;
	public void Dispose() mut { }
}

struct GameSpeedChangedMsg : IMessage
{
	public float NewSpeed;
	public void Dispose() mut { }
}

struct TowerSoldMsg : IMessage
{
	public EntityHandle EntityId;
	public TowerType Type;
	public int32 Refund;
	public void Dispose() mut { }
}

struct TowerSelectedMsg : IMessage
{
	public EntityHandle EntityId;
	public void Dispose() mut { }
}

struct TowerPlacedMsg : IMessage
{
	public EntityHandle EntityId;
	public TowerType Type;
	public int32 GridX;
	public int32 GridZ;
	public void Dispose() mut { }
}

struct TowerUpgradedMsg : IMessage
{
	public EntityHandle EntityId;
	public int32 NewLevel;
	public void Dispose() mut { }
}

struct ResourceChangedMsg : IMessage
{
	public int32 NewAmount;
	public int32 Delta;
	public void Dispose() mut { }
}

struct GameOverMsg : IMessage
{
	public bool Won;
	public void Dispose() mut { }
}

struct GamePhaseChangedMsg : IMessage
{
	public GamePhase OldPhase;
	public GamePhase NewPhase;
	public void Dispose() mut { }
}

struct TowerShotMsg : IMessage
{
	public EntityHandle TowerEntity;
	public EntityHandle TargetEntity;
	public Vector3 Origin;
	public TowerType TowerType;
	public void Dispose() mut { }
}

struct ProjectileHitMsg : IMessage
{
	public EntityHandle ProjectileEntity;
	public EntityHandle TargetEntity;
	public Vector3 HitPosition;
	public int32 Damage;
	public void Dispose() mut { }
}
