using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// Wanders the block on the navmesh: picks a spot around the ring road (on a verge or across it),
/// walks there, picks another. The block sets the walking speed (PedestrianSpeedChanged) and says
/// where the ring road runs (BlockRingChanged), which sets the band the walks stay in.
///
/// The figure (its child PedestrianModel) turns toward where it walks, easing round rather than
/// snapping, and its walk clip plays at the pace it walks.
[Behaviour("paperkid.pedestrian")]
[DisplayName("Pedestrian"), Category("PaperKid")]
[Description("Wanders the band round the ring road on the navmesh, turning toward where it walks and stepping at its pace.")]
class Pedestrian : Behaviour
{
	[Description("Walking speed until the Level sets one (m/s)")]
	public float Speed = 1.6f;
	[Description("Nearest the middle a walk may lead (m)")]
	public float Inner = 18.0f;
	[Description("Farthest from the middle a walk may lead (m)")]
	public float Outer = 31.0f;
	[Description("The figure's walk clip")]
	public Ref<AnimationClip> WalkClip = .(Guid());
	[Description("Metres the walk clip covers at speed 1")]
	public float WalkMetres = 1.3f;

	private bool mWalking = false;
	private EntityHandle mFigure = .Invalid;
	/// Radians; 0 faces +Z.
	private float mYaw = 0.0f;

	protected override void OnStart()
	{
		Listen<PedestrianSpeedChanged>(new [=this] (evt) =>
			{
				Speed = evt.Speed;
				SetMaxSpeed();
			});
		Listen<BlockRingChanged>(new [=this] (evt) =>
			{
				Inner = evt.Ring - 6.0f;
				Outer = evt.Ring + 7.0f;
				PickTarget();
			});
		SetMaxSpeed();
		PickTarget();
		mFigure = Scene.FindChildByName(Entity, "PedestrianModel");
		if (Scene.IsValid(mFigure) && (WalkClip.Id != Guid()))
			Feedback.PlayClip(Scene, mFigure, WalkClip.Id);
	}

	protected override void OnUpdate(float dt)
	{
		let agent = Get<NavAgentComponent>();
		if (agent == null)
			return;
		if (mWalking && agent.Finished)
			PickTarget();
		// Face the way the walk goes (turning the short way round, a few times a second), and
		// step at the pace of it; standing, the figure stands still.
		let v = agent.DesiredVelocity;
		let pace = Sqrt(v.X * v.X + v.Z * v.Z);
		if (pace > 0.05f)
		{
			var turn = Atan2(v.X, v.Z) - mYaw;
			while (turn > 3.14159f)
				turn -= 6.28318f;
			while (turn < -3.14159f)
				turn += 6.28318f;
			let ease = 8.0f * dt;
			mYaw += turn * ((ease < 1.0f) ? ease : 1.0f);
			Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
		}
		if (Scene.IsValid(mFigure))
			Feedback.ClipSpeed(Scene, mFigure, pace / WalkMetres);
	}

	private void SetMaxSpeed()
	{
		let agent = Get<NavAgentComponent>();
		if (agent != null)
			agent.MaxSpeed = Speed;
	}

	/// A point in the band around the ring road, on one of its four sides.
	private void PickTarget()
	{
		let random = Random;
		let along = Feedback.Range(random, -Outer, Outer);
		var across = Feedback.Range(random, Inner, Outer);
		if (Feedback.Toss(random))
			across = -across;
		var x = along;
		var z = across;
		if (Feedback.Toss(random))
		{
			x = across;
			z = along;
		}
		let agent = Get<NavAgentComponent>();
		if (agent != null)
			agent.Navigate(.(x, 0.0f, z));
		mWalking = true;
	}
}
