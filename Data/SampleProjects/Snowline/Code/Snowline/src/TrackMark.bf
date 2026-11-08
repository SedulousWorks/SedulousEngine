using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// One stretch of the board's track in the snow (Prefabs/TrackMark, Tools/effects.py): it lies as
/// it was dropped, fades its decal over the end of its life and removes itself, so the track
/// behind the rider stays a few seconds long.
[Behaviour("snowline.track_mark")]
[DisplayName("Track Mark"), Category("Snowline")]
[Description("One stretch of the board's track: fades its decal over the end of its life, then removes itself.")]
class TrackMark : Behaviour
{
	[Description("How long the mark lasts (s)")]
	public float Life = 6.0f;
	[Description("How long it takes to fade, at the end (s)")]
	public float Fade = 2.0f;

	private float mAge = 0.0f;
	/// The decal's alpha as authored, read at the first update.
	private float mAlpha = -1.0f;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnUpdate(float dt)
	{
		mAge += dt;
		let decal = Scene.GetFirstChild(Entity);
		if (Scene.IsValid(decal))
		{
			if (let mark = Scene.GetComponent<DecalComponent>(decal))
			{
				let c = mark.Color;
				if (mAlpha < 0.0f)
					mAlpha = c.A;
				let left = Life - mAge;
				let k = (left < Fade) ? ((left > 0.0f) ? left / Fade : 0.0f) : 1.0f;
				// The component is the live one: the decal is drawn with this colour from the next
				// extract on.
				mark.Color = Color(c.R, c.G, c.B, mAlpha * k);
			}
		}
		if (!mGone && (mAge >= Life))
		{
			mGone = true;
			Scene.DestroyEntity(Entity);
		}
	}
}
