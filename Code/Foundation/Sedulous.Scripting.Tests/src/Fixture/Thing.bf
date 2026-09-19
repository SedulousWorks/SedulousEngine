using System;
using Sedulous.Core;

namespace Sedulous.Scripting.Tests.Fixture;

/// A class with marked members only: a field, two properties, an overload set told apart
/// by ScriptName, a by-reference parameter, and a static factory.
[Scriptable]
class Thing
{
	[Scriptable]
	public int Count;
	public int NotExposed;

	[Scriptable]
	[Description("How fast.")]
	public float Speed { get; set; }
	[Scriptable]
	public bool Ready => true;

	[Scriptable]
	public void Go() {}
	[Scriptable, ScriptName("GoTo")]
	public void Go(Vec2 at) {}
	[Scriptable]
	public bool TryGet(int index, ref Vec2 outValue) => false;
	[Scriptable]
	public void Move(Vec2 to, float speed = 1.5f, bool teleport = false) {}
	[Scriptable]
	public static Thing Make() => new Thing();
	public void Internal() {}
}
