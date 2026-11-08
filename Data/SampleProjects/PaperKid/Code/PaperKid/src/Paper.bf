using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// A thrown newspaper. Entering any trigger, it tells that trigger's subscriber it arrived
/// (Subscriber.PaperArrived); only a delivery zone has one, so nothing here needs to know which
/// triggers are porches. Its first hard landing kicks up a puff of dust. Gone a while after it is
/// thrown, delivered or not.
[Behaviour("paperkid.paper")]
[DisplayName("Paper"), Category("PaperKid")]
[Description("A thrown paper: delivered to the porch whose zone it enters, a puff where it first lands hard, gone after its lifetime.")]
class Paper : Behaviour
{
	[Description("Seconds before the paper is gone")]
	public float Lifetime = 6.0f;

	private float mAge = 0.0f;
	private bool mLanded = false;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnTriggerEnter(EntityHandle other)
	{
		let subscriber = Scene.GetSystem<BehaviourManager<Subscriber>>()?.Get(other);
		if ((subscriber != null) && subscriber.IsActive)
			subscriber.PaperArrived();
	}

	protected override void OnContactBegin(EntityHandle other, Float3 point, Float3 normal, float speed)
	{
		if (mLanded || (speed < 2.0f))
			return;
		mLanded = true;
		Feedback.Spawn(Scene, Assets.FxPuff, point);
	}

	protected override void OnUpdate(float dt)
	{
		mAge += dt;
		if (!mGone && (mAge >= Lifetime))
		{
			mGone = true;
			Scene.DestroyEntity(Entity);
		}
	}
}
