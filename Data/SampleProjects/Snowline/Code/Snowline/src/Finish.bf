using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The finish line: when the rider crosses it down the course, RunFinished. It holds the course's
/// medal times too, and tells them as it starts (MedalTimes) for the game to judge a run by and the
/// medal ghosts to ride at. Placed by Tools/course.py at the course line's end, facing up the
/// course, with its course's times.
[Behaviour("snowline.finish")]
[DisplayName("Finish"), Category("Snowline")]
[Description("The finish line: ends the run when the rider crosses it, and holds the course's medal times.")]
class Finish : Behaviour
{
	[Description("The course's heading at the finish (radians; 0 runs toward +Z)")]
	public float Heading = 0.0f;
	[Description("A gold medal's time, penalties included (s)")]
	public float Gold = 50.0f;
	[Description("A silver medal's time (s)")]
	public float Silver = 56.0f;
	[Description("A bronze medal's time (s)")]
	public float Bronze = 64.0f;

	private EntityHandle mRider = .Invalid;
	private bool mCrossed = false;
	private bool mSeen = false;
	private float mLastAlong = 0.0f;

	protected override void OnStart()
	{
		// A new run: the line waits for the rider again.
		Listen<RunRestart>(new [=this] (evt) =>
			{
				mCrossed = false;
				mSeen = false;
			});
		mRider = Scene.FindEntityByName("Rider");
		Post(MedalTimes(Gold, Silver, Bronze));
	}

	protected override void OnUpdate(float dt)
	{
		if (mCrossed || !Scene.IsValid(mRider))
			return;
		let along = Pieces.Along(Scene.GetWorldPosition(mRider) - Scene.GetWorldPosition(Entity), Heading);
		if (mSeen && (mLastAlong < 0.0f) && (along >= 0.0f))
		{
			mCrossed = true;
			Post(RunFinished(Entity));
		}
		mLastAlong = along;
		mSeen = true;
	}
}
