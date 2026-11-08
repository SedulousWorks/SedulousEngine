using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// Moves an entity back and forth and spins it: a saw sliding along its track, a spiky ball
/// swinging across a bridge. The motion is a smooth swing (a sine) from where it was placed,
/// Distance either side along Axis; the spin is about SpinAxis. With a Hazard on the same entity,
/// the hazard hurts wherever the mover has taken it.
[Behaviour("skyhopper.mover")]
[DisplayName("Mover"), Category("Sky Hopper")]
[Description("Swings the entity back and forth along an axis from where it was placed, and spins it.")]
class Mover : Behaviour
{
	[Description("The direction it swings along")]
	public Float3 Axis = .(1.0f, 0.0f, 0.0f);
	[Description("How far either side of its place it swings (m)")]
	public float Distance = 2.0f;
	[Description("Swings per second (Hz)")]
	public float Rate = 1.0f;
	[Description("Where in its swing it starts, 0 to 1 (staggers several movers)")]
	public float Phase = 0.0f;
	[Description("The axis it spins about")]
	public Float3 SpinAxis = .(0.0f, 0.0f, 1.0f);
	[Description("Spin rate (rad/s)")]
	public float SpinSpeed = 0.0f;

	private Float3 mHome = .(0.0f, 0.0f, 0.0f);
	private Quaternion mRest = .Identity;
	private float mTime = 0.0f;

	protected override void OnStart()
	{
		let local = Scene.GetLocalTransform(Entity);
		mHome = local.Position;
		mRest = local.Rotation;
	}

	protected override void OnUpdate(float dt)
	{
		mTime += dt;
		let swing = Sin((mTime * Rate + Phase) * 6.28318f) * Distance;
		Scene.SetLocalPosition(Entity, mHome + Axis * swing);
		if (SpinSpeed != 0.0f)
			Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(SpinAxis, mTime * SpinSpeed) * mRest);
	}
}
