using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

enum MoverMood : int32
{
	Calm,
	Angry,
	Asleep
}

/// A behaviour with one field of each kind a saved behaviour holds, and a private field of
/// runtime state that is neither saved nor shown.
[Behaviour("test.mover"), DisplayName("Mover"), Category("Tests")]
class Mover : Behaviour
{
	/// How many started movers OnDestroy has seen, and whether the last one still reached
	/// its entity's Tag: what the ownership tests count.
	public static int Destroyed = 0;
	public static bool LastDestroyFoundTag = false;

	public float Speed = 2.5f;
	public int32 Lives = 3;
	public bool Flying = false;
	public String Label = new .("mover") ~ delete _;
	public Float3 Heading = .(0.0f, 0.0f, 1.0f);
	public EntityRef Target = .();
	public MoverMood Mood = .Calm;

	private float mBob = 0.0f;

	/// The runtime state, reached the way game code would.
	public float Bob
	{
		get => mBob;
		set => mBob = value;
	}

	protected override void OnDestroy()
	{
		Destroyed++;
		LastDestroyFoundTag = (Scene != null) && (Get<Tag>() != null);
	}
}

/// A behaviour with no fields of its own: its record is the base's alone.
[Behaviour("test.marker")]
class Marker : Behaviour
{
}

/// A plain value component, for Behaviour.Get<T>.
struct Tag
{
	public int32 Value = 0;

	public this() {}
}
