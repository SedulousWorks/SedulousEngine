using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// The upper floor's bell: when a guard gives chase (ThiefSpotted), it rings, and every guard on the
/// floor hears it and comes to where the thief was seen (a Noise there, loud enough for the whole
/// floor; a guard already giving chase keeps chasing). The game says so (AlarmRung). Once rung it
/// rests a while before it can ring again.
[Behaviour("lamplight.alarm")]
[DisplayName("Alarm"), Category("Lamplight")]
[Description("A bell a guard's chase rings, bringing every guard on the floor to where the thief was seen.")]
class Alarm : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();
	[Description("How loud: a noise of loudness 1 is heard 14 m away")]
	public float Loudness = 40.0f;
	[Description("Seconds before it can ring again")]
	public float Rest = 8.0f;

	/// The thief Thief names in this scene, found as it starts.
	private EntityHandle mThief = .Invalid;
	/// Seconds left before it can ring again.
	private float mResting = 0.0f;

	protected override void OnStart()
	{
		Listen<ThiefSpotted>(new [=this] (evt) => Ring());
		mThief = Scene.FindEntity(Thief.Id);
	}

	protected override void OnUpdate(float dt)
	{
		if (mResting > 0.0f)
			mResting -= dt;
	}

	private void Ring()
	{
		if ((mResting > 0.0f) || !Scene.IsValid(mThief))
			return;
		mResting = Rest;
		let at = Scene.GetWorldPosition(mThief);
		Pieces.PlayAt(Run, Assets.BellSound, at);
		Post(Noise(at, Loudness));
		Post(AlarmRung(at));
	}
}
