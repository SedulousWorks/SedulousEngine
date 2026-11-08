using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// A flame's light that will not hold still: its intensity wanders round what it was authored at,
/// two slow waves and a quick one, so a torch breathes rather than burns flat. Off (a torch put
/// out, Lamp) it stays off.
[Behaviour("lamplight.flicker")]
[DisplayName("Flicker"), Category("Lamplight")]
[Description("Makes its light's intensity wander round its own, as a flame's does.")]
class Flicker : Behaviour
{
	[Description("How far the intensity wanders, as a share of its own")]
	public float Amount = 0.18f;
	[Description("How fast it wanders")]
	public float Rate = 1.0f;

	/// The intensity it was authored at.
	private float mBase = 0.0f;
	private float mTime = 0.0f;

	protected override void OnStart()
	{
		if (let light = Get<LightComponent>())
			mBase = light.Intensity;
		let at = Scene.GetWorldPosition(Entity);
		mTime = at.X * 1.7f + at.Z * 0.9f; // each torch its own
	}

	protected override void OnUpdate(float dt)
	{
		mTime += dt * Rate;
		let wave = 0.5f * Sin(mTime * 2.3f) + 0.3f * Sin(mTime * 5.1f + 1.3f) + 0.2f * Sin(mTime * 13.7f + 0.4f);
		if (let light = Get<LightComponent>())
			light.Intensity = mBase * (1.0f + Amount * wave);
	}
}
