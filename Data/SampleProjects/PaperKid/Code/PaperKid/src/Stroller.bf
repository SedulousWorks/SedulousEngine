using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// Crosses the title backdrop along X, from XFrom to XTo, then after a pause comes round again from
/// the start: a car on the road or a person on the pavement. It moves itself, not a navigation
/// agent (the backdrop has no navmesh), and faces the way it goes.
///
/// Its model is its first child. With a walk clip, the clip plays at the pace it moves (over the
/// metres the clip covers at speed 1); a car has none.
[Behaviour("paperkid.stroller")]
[DisplayName("Stroller"), Category("PaperKid")]
[Description("Crosses the title backdrop along X and comes round again after a pause, its walk clip, if any, at its pace.")]
class Stroller : Behaviour
{
	[Description("Where each crossing starts (m along X)")]
	public float XFrom = -30.0f;
	[Description("Where each crossing ends (m along X)")]
	public float XTo = 30.0f;
	[Description("Speed (m/s)")]
	public float Speed = 1.4f;
	[Description("Longest pause between crossings (s)")]
	public float Pause = 6.0f;
	[Description("The model's walk clip, if it walks")]
	public Ref<AnimationClip> WalkClip = .(Guid());
	[Description("Metres the walk clip covers at speed 1")]
	public float WalkMetres = 1.3f;

	private float mX = 0.0f;
	private float mWait = 0.0f;
	private EntityHandle mModel = .Invalid;

	protected override void OnStart()
	{
		// Somewhere along the way already, so the backdrop is busy from the first frame.
		mX = Feedback.Range(Random, XFrom, XTo);
		let heading = (XTo > XFrom) ? 90.0f : -90.0f;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(DegreesToRadians(heading), 0.0f, 0.0f));
		Place();
		mModel = Scene.GetFirstChild(Entity);
		if (Scene.IsValid(mModel) && (WalkClip.Id != Guid()))
		{
			Feedback.PlayClip(Scene, mModel, WalkClip.Id);
			Feedback.ClipSpeed(Scene, mModel, Speed / WalkMetres);
		}
	}

	protected override void OnUpdate(float dt)
	{
		if (mWait > 0.0f)
		{
			mWait -= dt;
			if (mWait <= 0.0f)
			{
				mX = XFrom;
				Place();
			}
			return;
		}
		let way = (XTo > XFrom) ? 1.0f : -1.0f;
		mX += way * Speed * dt;
		if ((mX - XTo) * way >= 0.0f)
			mWait = Feedback.Range(Random, 0.5f, Pause);
		Place();
	}

	private void Place()
	{
		let p = Scene.GetLocalTransform(Entity).Position;
		Scene.SetLocalPosition(Entity, .(mX, p.Y, p.Z));
	}
}
