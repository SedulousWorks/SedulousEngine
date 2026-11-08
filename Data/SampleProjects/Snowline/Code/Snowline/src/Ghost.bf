using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The medal a ghost rides at.
enum GhostMedal : uint8
{
	case Gold = 0;
	case Silver = 1;
	case Bronze = 2;
}

/// A medal's ghost rider: it rides the course line at the pace that crosses the finish at its
/// medal's time, so a rider racing it knows where that medal stands. On the ghost's entity, which
/// follows the line (a path follow on the Course spline); its first child is the rider model,
/// tinted and see-through. Placed by Tools/course.py, one per medal.
///
/// Its time comes from the finish line (MedalTimes). The pace eases in over RampSeconds, as a rider
/// gathers speed off the start, then holds: the distance at time t is v t^2 / 2r while ramping,
/// then v (t - r/2), and v is chosen so that the distance reaches FinishDistance at the medal's
/// time. It sets off with the rider (RunStarted), and a new run (RunRestart) starts it over.
[Behaviour("snowline.ghost")]
[DisplayName("Ghost"), Category("Snowline")]
[Description("A medal's ghost rider: rides the course line at the pace that crosses the finish at its medal's time.")]
class Ghost : Behaviour
{
	[Description("Which medal")]
	public GhostMedal Medal = .Gold;
	[Description("How far down the course line the finish is (m)")]
	public float FinishDistance = 0.0f;
	[Description("How long it takes to reach its pace off the start (s)")]
	public float RampSeconds = 3.0f;

	/// The medal's time.
	private float mSeconds = 0.0f;
	/// Run time.
	private float mTime = 0.0f;
	/// The rider has set off.
	private bool mRunStarted = false;
	private EntityHandle mModel = .Invalid;

	protected override void OnStart()
	{
		Listen<MedalTimes>(new [=this] (evt) => Take(evt));
		Listen<RunStarted>(new [=this] (evt) => { mRunStarted = true; });
		Listen<RunRestart>(new [=this] (evt) => Restart());
		mModel = Scene.GetFirstChild(Entity);
	}

	protected override void OnUpdate(float dt)
	{
		if ((mSeconds <= 0.0f) || !mRunStarted)
			return;
		let follow = Get<PathFollowComponent>();
		if (follow == null)
			return;
		mTime += dt;
		let cruise = FinishDistance / (mSeconds - RampSeconds * 0.5f);
		follow.Speed = (mTime < RampSeconds) ? cruise * mTime / RampSeconds : cruise;
		Settle();
	}

	/// A new run: back to the top, off again.
	private void Restart()
	{
		mTime = 0.0f;
		if (let follow = Get<PathFollowComponent>())
		{
			follow.Distance = 0.0f;
			follow.Speed = 0.0f;
			follow.Playing = true;
		}
	}

	private void Take(MedalTimes times)
	{
		switch (Medal)
		{
		case .Gold: mSeconds = times.Gold;
		case .Silver: mSeconds = times.Silver;
		case .Bronze: mSeconds = times.Bronze;
		}
	}

	/// The line is a smooth curve through points on the snow, so between them it can run above or
	/// below it: the model sits on the snow found under the line, not on the line.
	private void Settle()
	{
		if (!Scene.IsValid(mModel))
			return;
		let at = Scene.GetWorldPosition(Entity);
		var y = 0.0f;
		if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
		{
			let hit = physics.RayCast(.(at.X, at.Y + 4.0f, at.Z), .(0.0f, -1.0f, 0.0f), 10.0f, 1);
			if (hit.Hit)
				y = hit.Position.Y - at.Y;
		}
		Scene.SetLocalPosition(mModel, .(0.0f, y, 0.0f));
	}
}
