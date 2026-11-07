using System;
using Sedulous.Core;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Editor.Scene.Tests;

/// A level for the editor's paths: a field the inspector edits and reverts beside the base's
/// Active, and a private field of runtime state it never shows.
[Level("test.siege"), DisplayName("Siege"), Category("Tests")]
class Siege : Level
{
	public int32 Waves = 4;

	private float mClock = 0.0f;

	/// The runtime state, as game code reaches it.
	public float Clock => mClock;
}
