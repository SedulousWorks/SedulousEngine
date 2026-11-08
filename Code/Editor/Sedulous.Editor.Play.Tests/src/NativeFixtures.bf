using System;
using Sedulous.Core;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Editor.Play.Tests;

/// Reflected, as an enum a native field uses must be for the tools to name its values.
[Reflect]
enum PiePhase : int32
{
	Lobby = 0,
	Round = 1,
	Over = 2
}

/// A native game for the PIE probes: a public field beside private runtime state of the kinds
/// a probe reads (a number, an enum, a vector), which a test moves as play would.
[Game]
class PieArcadeGame : Game
{
	public int32 Lives = 3;

	private int32 mRoundsUp = 0;
	private PiePhase mPhase = .Lobby;
	private Float3 mSpawn = .(1.0f, 2.0f, 3.0f);

	/// A round runs out: counted, and the phase over.
	public void EndRound()
	{
		mRoundsUp++;
		mPhase = .Over;
	}
}

/// What a Game tab's run launches when a test wants the native game the probes read: a fresh
/// PieArcadeGame each time, which the run owns.
class PieArcadeFactory : IGameFactory
{
	public int Made = 0;

	public IGameHooks CreateGame(GameInstance instance)
	{
		Made++;
		return new PieArcadeGame();
	}
}

/// A level for the probes, with a setting and private runtime state.
[Level("pietest.arena")]
class PieArena : Level
{
	public float TimeLimit = 60.0f;

	private float mRemaining = 42.0f;

	/// The runtime state, as game code reaches it.
	public float Remaining => mRemaining;
}

/// A second level, so a scene can run two and a probe must name one.
[Level("pietest.vault")]
class PieVault : Level
{
	public int32 Quota = 4;

	private int32 mLooted = 0;

	public void Loot()
	{
		mLooted++;
	}
}

/// A behaviour for the probes, with a setting and private runtime state.
[Behaviour("pietest.mover")]
class PieMover : Behaviour
{
	public float Speed = 2.0f;

	private float mTravelled = 0.0f;

	public void Travel(float distance)
	{
		mTravelled += distance;
	}
}
