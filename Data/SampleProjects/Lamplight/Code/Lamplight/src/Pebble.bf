using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// A thrown stone (the Thief throws it). Its first hard landing clacks and makes a Noise there, loud
/// enough to draw a guard who hears it away to look. Gone a while after.
[Behaviour("lamplight.pebble")]
[DisplayName("Pebble"), Category("Lamplight")]
[Description("A thrown stone: its first hard landing clacks and makes a noise the guards hear; gone after its lifetime.")]
class Pebble : Behaviour
{
	[Description("How loud its landing is (0..1)")]
	public float Loudness = 1.0f;
	[Description("Landing slower than this (m/s) is not a clack")]
	public float HardLanding = 1.5f;
	[Description("Seconds before the pebble is gone")]
	public float Lifetime = 6.0f;

	private float mAge = 0.0f;
	private bool mLanded = false;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnContactBegin(EntityHandle other, Float3 point, Float3 normal, float speed)
	{
		if (mLanded || (speed < HardLanding))
			return;
		mLanded = true;
		Pieces.PlayAt(Run, Assets.StepStone2, point);
		Post(Noise(point, Loudness));
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
