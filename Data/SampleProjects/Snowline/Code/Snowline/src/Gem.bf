using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// A pickup off the safe line: it spins and bobs, and when the rider comes within reach it is taken
/// (GemCollected), with a sparkle and a chime. Taken, its model hides; the gem itself stays, so a new
/// run (RunRestart) brings it back. On the gem's entity, whose first child is the Gem model. Placed
/// by Tools/course.py, in rows beside the course between the gates.
[Behaviour("snowline.gem")]
[DisplayName("Gem"), Category("Snowline")]
[Description("A pickup that spins and bobs, and is taken with a sparkle and a chime when the rider comes within reach.")]
class Gem : Behaviour
{
	[Description("Pickup reach from the rider's centre (m)")]
	public float Radius = 1.4f;
	[Description("Spin rate (rad/s)")]
	public float SpinSpeed = 2.5f;
	[Description("Bob height (m)")]
	public float BobHeight = 0.15f;
	[Description("Gems this one counts for")]
	public int32 Value = 1;

	private EntityHandle mRider = .Invalid;
	private EntityHandle mModel = .Invalid;
	private bool mTaken = false;
	private float mTime = 0.0f;

	protected override void OnStart()
	{
		// A new run: the gem is back for the taking.
		Listen<RunRestart>(new [=this] (evt) =>
			{
				mTaken = false;
				if (Scene.IsValid(mModel))
					Scene.SetActive(mModel, true);
			});
		mRider = Scene.FindEntityByName("Rider");
		mModel = Scene.GetFirstChild(Entity);
		// Gems along the course bob out of step with each other.
		mTime = Scene.GetWorldPosition(Entity).Z * 0.37f;
		Post(GemRegistered(Value));
	}

	protected override void OnUpdate(float dt)
	{
		if (mTaken || !Scene.IsValid(mModel))
			return;
		mTime += dt;
		Scene.SetLocalRotation(mModel, Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mTime * SpinSpeed));
		Scene.SetLocalPosition(mModel, .(0.0f, Sin(mTime * 2.2f) * BobHeight, 0.0f));
		if (!Scene.IsValid(mRider))
			return;
		// A world position read in an update is this frame's.
		let here = Scene.GetWorldPosition(Entity);
		if (Distance(Scene.GetWorldPosition(mRider), here) < Radius)
		{
			mTaken = true;
			Scene.SetActive(mModel, false);
			Post(GemCollected(Value));
			Pieces.Spawn(Scene, Assets.GemSparkle, here);
			Pieces.Play(Run, Assets.GemChime, .Effects, 0.6f);
		}
	}
}
