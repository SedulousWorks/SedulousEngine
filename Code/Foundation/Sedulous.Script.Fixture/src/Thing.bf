using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Script;

namespace Sedulous.Script.Fixture;

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
	public void Go() { Goes++; }
	[Scriptable, ScriptName("GoTo")]
	public void Go(Vec2 at) { LastTarget = at; }
	[Scriptable]
	public bool TryGet(int index, ref Vec2 outValue)
	{
		outValue = .(index, index);
		return index >= 0;
	}
	[Scriptable]
	public void Move(Vec2 to, float speed = 1.5f, bool teleport = false)
	{
		LastTarget = to;
		LastSpeed = speed;
		LastTeleport = teleport;
	}
	[Scriptable]
	public void SetMode(Mode mode) { LastMode = mode; }
	[Scriptable]
	public Mode GetMode() => LastMode;
	[Scriptable]
	public StringView Label() => "thing";
	[Scriptable]
	public Vec2 Bounds() => .(3, 4);
	/// A resource reference on a class with no manager: crosses as its Guid.
	[Scriptable]
	public Ref<Thing> Buddy = .(Guid());
	/// An overload set a resolver must pick through: the integer and the float.
	[Scriptable]
	public void Follow(Thing other) { Leader = other; }
	public Thing Leader;
	[Scriptable]
	public int Twice(int x) => x * 2;
	[Scriptable]
	public float Twice(float x) => x * 2;

	// ---- lists, which cross by copy in both directions ----

	/// A list field: read as a copy, written by replacing the contents.
	[Scriptable]
	public List<Vec2> Points = new .() ~ delete _;
	/// A list in: summed.
	[Scriptable]
	public float Sum(List<float> values)
	{
		float total = 0;
		for (let v in values)
			total += v;
		return total;
	}
	/// A list out: the caller's list filled with 1..count, as OverlapSphere fills one.
	[Scriptable]
	public int Fill(List<int> outValues, int count)
	{
		for (int i = 1; i <= count; i++)
			outValues.Add(i);
		return outValues.Count;
	}
	/// A list result, of objects.
	[Scriptable]
	public List<Thing> Followers()
	{
		return mFollowers;
	}
	public List<Thing> mFollowers = new .() ~ delete _;

	// ---- a callback, held by the native side ----

	/// A script function to call back: OWNED, replaced by the next, null clears.
	public ScriptDelegate Handler = null ~ delete _;
	[Scriptable]
	public void OnPoke(ScriptDelegate handler)
	{
		delete Handler;
		Handler = handler;
	}
	/// Fires the held callback; false when none, dead, or faulted.
	[Scriptable]
	public bool FirePoke() => (Handler != null) && Handler.Invoke();

	// Observed by the tests, not on the surface.
	public Vec2 LastTarget;
	public float LastSpeed;
	public bool LastTeleport;
	public Mode LastMode = .Off;
	public int Goes;
	[Scriptable]
	public static Thing Make() => new Thing();
	public void Internal() {}
}
