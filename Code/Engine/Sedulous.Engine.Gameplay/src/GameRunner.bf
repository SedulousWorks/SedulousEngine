using System;
using System.Collections;
using Sedulous.Run;
using Sedulous.Engine.GameInstance;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// The engine's hold on the build's Game: a run listener (EnginePluginServices.AddRunListener,
/// through GameplayServices.SetGame) that offers itself to every run as its game factory
/// (IGameFactory), so each run's LaunchGame makes the game. The engine owns it; as it is deleted
/// (its plugin unloaded) it takes itself off the runs still alive, and their later launches find
/// no game. A game already running stays the run's until its session ends.
class GameRunner : IRunListener, IGameFactory
{
	/// Makes the build's game.
	private function Game() mCreate;
	/// BORROWED: the runs it is offered on, each left as it is destroyed.
	private List<RunBase> mOfferedTo = new .() ~ delete _;

	public this(function Game() create)
	{
		mCreate = create;
	}

	/// Off every run it is still offered on, where it is still the factory.
	public ~this()
	{
		for (let run in mOfferedTo)
		{
			if (run.FindService(typeof(IGameFactory)) === this)
				run.Remove<IGameFactory>();
		}
		mOfferedTo.Clear();
	}

	/// How many runs it is offered on.
	public int OfferCount => mOfferedTo.Count;

	public IGameHooks CreateGame(GameInstance instance)
	{
		let game = mCreate();
		if (game != null)
			game.Bind(instance);
		return game;
	}

	public void OnRunCreated(IRun run)
	{
		let held = run as RunBase;
		if ((held == null) || mOfferedTo.Contains(held))
			return;
		held.Register<IGameFactory>(this);
		mOfferedTo.Add(held);
	}

	public void OnRunDestroyed(IRun run)
	{
		for (int i < mOfferedTo.Count)
		{
			if ((Object)mOfferedTo[i] == (Object)run)
			{
				mOfferedTo.RemoveAt(i);
				return;
			}
		}
	}
}
