using System;
using Sedulous.Scene;

namespace SkyHopper;

// What a level's behaviours tell the game, each posted to the run (Behaviour.Post) and heard by
// SkyHopperGame at the run's drain, at the end of the frame.

/// A coin started: the level has `Count` more to collect.
struct CoinRegistered
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// The player took a coin worth `Value` coins.
struct CoinCollected
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// The player stomped `Count` enemies.
struct EnemyDefeated
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// The player took a heart: `Count` lives back.
struct LifeCollected
{
	public int32 Count;

	public this(int32 count)
	{
		Count = count;
	}
}

/// The player took the level's gem.
struct GemCollected
{
	public int32 Value;

	public this(int32 value)
	{
		Value = value;
	}
}

/// The player fell out or was hurt, and respawns: `Deaths` in the level so far.
struct PlayerDied
{
	public int32 Deaths;

	public this(int32 deaths)
	{
		Deaths = deaths;
	}
}

/// The player reached the flag, `Flag`: the level is won.
struct GoalReached
{
	public EntityHandle Flag;

	public this(EntityHandle flag)
	{
		Flag = flag;
	}
}
