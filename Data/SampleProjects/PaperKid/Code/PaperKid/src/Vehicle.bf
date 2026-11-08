using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// Drives laps of the ring road on the navmesh, corner to corner, in its lane: the ring it is
/// placed on (its distance from the middle along the nearer axis), so one prefab drives any
/// block's ring. Inner lanes lap clockwise, outer ones anticlockwise (Direction). The block sets
/// the speed (TrafficSpeedChanged).
[Behaviour("paperkid.vehicle")]
[DisplayName("Vehicle"), Category("PaperKid")]
[Description("Drives laps of the ring road it is placed on, corner to corner on the navmesh, facing the way it drives.")]
class Vehicle : Behaviour
{
	[Description("1 laps clockwise (seen from above), -1 anticlockwise")]
	public int32 Direction = 1;
	[Description("Driving speed until the Level sets one (m/s)")]
	public float Speed = 6.0f;

	private int32 mCorner = 0;
	private float mLane = 22.0f;

	protected override void OnStart()
	{
		Listen<TrafficSpeedChanged>(new [=this] (evt) =>
			{
				Speed = evt.Speed;
				SetMaxSpeed();
			});
		SetMaxSpeed();
		// Head for the corner ahead of where the car stands.
		let at = Scene.GetWorldPosition(Entity);
		mLane = (Abs(at.X) > Abs(at.Z)) ? Abs(at.X) : Abs(at.Z);
		mCorner = NearestCorner(at);
		Advance();
	}

	protected override void OnUpdate(float dt)
	{
		let agent = Get<NavAgentComponent>();
		if (agent == null)
			return;
		if (agent.Finished)
			Advance();
		// Face the way it drives.
		let v = agent.DesiredVelocity;
		if (v.X * v.X + v.Z * v.Z > 0.25f)
			Scene.SetLocalRotation(Entity, FromYawPitchRoll(Atan2(v.X, v.Z), 0.0f, 0.0f));
	}

	private void SetMaxSpeed()
	{
		let agent = Get<NavAgentComponent>();
		if (agent != null)
			agent.MaxSpeed = Speed;
	}

	private void Advance()
	{
		mCorner = (mCorner + Direction + 4) % 4;
		let agent = Get<NavAgentComponent>();
		if (agent != null)
			agent.Navigate(Corner(mCorner));
	}

	/// The ring's corners, clockwise seen from above (+Y): north-west, north-east, south-east,
	/// south-west, on this car's lane.
	private Float3 Corner(int32 index)
	{
		switch (index)
		{
		case 0: return .(-mLane, 0.0f, -mLane);
		case 1: return .(mLane, 0.0f, -mLane);
		case 2: return .(mLane, 0.0f, mLane);
		default: return .(-mLane, 0.0f, mLane);
		}
	}

	private int32 NearestCorner(Float3 at)
	{
		int32 best = 0;
		var bestDistance = 1.0e9f;
		for (int32 i < 4)
		{
			let c = Corner(i);
			let d = (c.X - at.X) * (c.X - at.X) + (c.Z - at.Z) * (c.Z - at.Z);
			if (d < bestDistance)
			{
				bestDistance = d;
				best = i;
			}
		}
		return best;
	}
}
