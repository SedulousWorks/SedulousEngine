using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// A house that takes the paper. On the delivery zone in front of its porch (a static trigger),
/// whose child "Marker" floats above to show the house wants one. The first paper to arrive
/// (PaperArrived, called by a Paper) is a delivery: Delivered goes out with the points, the marker
/// goes, and the zone switches itself off: it takes no more papers, and an inactive entity has no
/// trigger, so the bike's auto-aim (an overlap of the zone group) no longer finds it and stops
/// drawing its arc and ring to a porch already served. A delivery sounds: the paper slapping the
/// porch and a chime, sparkles off the porch, and a tap on the pad.
///
/// The block (which tallies the quota) and the game (which keeps score) both hear the one Delivered.
[Behaviour("paperkid.subscriber")]
[DisplayName("Subscriber"), Category("PaperKid")]
[Description("A porch that takes the first paper to land in its zone: a delivery worth its points, then it switches itself off.")]
class Subscriber : Behaviour
{
	[Description("Points for this delivery")]
	public int32 Value = 100;

	private bool mDelivered = false;

	/// A paper landed in the zone: the first is the delivery.
	public void PaperArrived()
	{
		if (mDelivered)
			return;
		mDelivered = true;
		Feedback.Play(Run, Assets.LandSound, .Effects, 0.9f, Feedback.Range(Random, 0.95f, 1.05f));
		Feedback.Play(Run, Assets.DeliveredSound, .Effects, 0.8f);
		Feedback.Rumble(Run, 0.1f, 0.45f, 0.1f); // a delivery's tap
		Feedback.Spawn(Scene, Assets.FxSparkle, Scene.GetLocalTransform(Entity).Position + Float3(0.0f, 0.3f, 0.0f));
		Post(Delivered(Value));
		let marker = Scene.FindChildByName(Entity, "Marker");
		if (Scene.IsValid(marker))
			Scene.SetActive(marker, false);
		Scene.SetActive(Entity, false);
	}
}
