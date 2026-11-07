using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Editor.Scene.Tests;

/// A behaviour for the editor's paths: a float, an enum, an entity reference and a string the
/// tools set beside the base's Enabled, and a private field of runtime state they never show.
[Behaviour("test.hopper"), DisplayName("Hopper"), Category("Tests"), Description("Hops when told to.")]
class Hopper : Behaviour
{
	public float Height = 1.5f;
	public TestMode Mode = .Off;
	public EntityRef Target = .();
	public String Label = new .("hop") ~ delete _;

	private float mAirTime = 0.0f;

	/// The runtime state, as game code reaches it.
	public float AirTime
	{
		get => mAirTime;
		set => mAirTime = value;
	}
}
