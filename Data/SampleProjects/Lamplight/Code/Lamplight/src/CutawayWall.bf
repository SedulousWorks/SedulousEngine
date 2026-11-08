using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// A wall piece that gets out of the camera's way: it fades while the line from the camera to the
/// thief crosses it (along the floor, the piece widened by Margin either side so the thief's
/// shoulders and a step ahead show too), and comes back when it no longer does. The fade is the
/// renderer's screen-door dither (MeshComponent.Fade), eased in and out; the piece keeps casting
/// its whole shadow, so what is behind it stays as dark as it was.
[Behaviour("lamplight.cutaway_wall")]
[DisplayName("Cutaway Wall"), Category("Lamplight")]
[Description("A wall piece that fades out while it stands between the camera and the thief.")]
class CutawayWall : Behaviour
{
	[Description("The camera")]
	public EntityRef Camera = .();
	[Description("The thief")]
	public EntityRef Thief = .();
	[Description("The piece's face direction (its normal), x")]
	public float NormalX = 0.0f;
	[Description("The piece's face direction (its normal), z")]
	public float NormalZ = 1.0f;
	[Description("Half the piece's length along its face (m)")]
	public float HalfLength = 1.0f;
	[Description("How much wider than the piece the line may pass and still fade it (m)")]
	public float Margin = 1.0f;
	[Description("How far it fades while in the way (1 = gone)")]
	public float Cutaway = 0.85f;
	[Description("How quickly it fades in or out (per second)")]
	public float Speed = 4.0f;

	/// The entities the references name in this scene, found as it starts.
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mThief = .Invalid;
	/// How far it is faded now.
	private float mFade = 0.0f;

	protected override void OnStart()
	{
		mCamera = Scene.FindEntity(Camera.Id);
		mThief = Scene.FindEntity(Thief.Id);
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mCamera) || !Scene.IsValid(mThief))
			return;
		let want = InTheWay() ? Cutaway : 0.0f;
		let step = Speed * dt;
		let next = (mFade < want) ? Min(mFade + step, want) : Max(mFade - step, want);
		if (next != mFade)
		{
			mFade = next;
			if (let mesh = Get<MeshComponent>())
				mesh.Fade = mFade;
		}
	}

	/// Whether the camera-to-thief line crosses the piece (in the floor's plane): the two ends lie
	/// on opposite sides of its face, and where the line crosses the face is within its widened
	/// length.
	private bool InTheWay()
	{
		let at = Scene.GetWorldPosition(Entity);
		let c = Scene.GetWorldPosition(mCamera);
		let t = Scene.GetWorldPosition(mThief);
		let cameraSide = (c.X - at.X) * NormalX + (c.Z - at.Z) * NormalZ;
		let thiefSide = (t.X - at.X) * NormalX + (t.Z - at.Z) * NormalZ;
		if ((cameraSide > 0.0f) == (thiefSide > 0.0f))
			return false;
		let k = cameraSide / (cameraSide - thiefSide); // where along camera-to-thief it crosses
		let x = c.X + (t.X - c.X) * k - at.X;
		let z = c.Z + (t.Z - c.Z) * k - at.Z;
		let along = x * -NormalZ + z * NormalX; // the face's own direction
		return (along >= -(HalfLength + Margin)) && (along <= HalfLength + Margin);
	}
}
