using System;
using Sedulous.Core.Logging;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace NativeSample;

/// The reference game's code for the whole run: it says it launched, keeps the name of each scene
/// that becomes current, and hears the Arena's round run out, which it counts and logs. Each
/// play (a player's run, a Game tab's Play) makes a fresh one.
[Game]
class NativeSampleGame : Game
{
	/// The scene that became current last; empty before the first.
	private String mSceneName = new .() ~ delete _;
	private int mScenesActivated = 0;
	private int mRoundsUp = 0;
	private float mLastTimeLimit = 0.0f;

	/// The name of the scene that became current last; empty before the first.
	public StringView SceneName => mSceneName;
	/// How many scenes became current this run.
	public int ScenesActivated => mScenesActivated;
	/// How many of the Arena's rounds ran out this run, and the last one's limit.
	public int RoundsUp => mRoundsUp;
	public float LastTimeLimit => mLastTimeLimit;

	protected override void OnLaunch()
	{
		GlobalLog(.Information, "NativeSample: the game launched");
		Listen<ArenaTimeUp>(new [=this] (evt) =>
			{
				mRoundsUp++;
				mLastTimeLimit = evt.TimeLimit;
				GlobalLog(.Information, scope $"NativeSample: the game heard the {evt.TimeLimit} second round end");
			});
	}

	protected override void OnSceneActivated(Sedulous.Scene.Scene scene)
	{
		mSceneName.Set(scene.Name);
		mScenesActivated++;
		GlobalLog(.Information, scope $"NativeSample: the game is in the scene '{scene.Name}'");
	}

	protected override void OnExit()
	{
		GlobalLog(.Information, scope $"NativeSample: the game exits after {mRoundsUp} round(s)");
	}
}
