using System;
using Sedulous.Core;

namespace Sedulous.Script.Fixture;

/// A class scripts hold weakly: its owner (the test) makes and destroys it, and a handle a
/// script kept may outlive it. In its table from construction, out of it when destroyed. No
/// constructor is marked: a weakly held type is made by its owner.
[Scriptable]
class Gadget : IScriptWeaklyHeld
{
	/// BORROWED: the table the gadget is in, null when in none.
	private FakeWeakTable mTable;
	private uint32 mSlot;
	private uint32 mGeneration;

	[Scriptable]
	public int Charge;
	[Scriptable]
	public float Level { get; set; }
	[Scriptable]
	public Gadget Other;

	/// Observed by the tests: whether the last Holds was handed null.
	public bool SawNull;

	public this(FakeWeakTable table)
	{
		mTable = table;
		if (table != null)
		{
			mSlot = table.Take(this);
			mGeneration = table.GenerationOf(mSlot);
		}
	}

	public ~this()
	{
		if (mTable != null)
			mTable.Free(mSlot);
	}

	public uint32 Slot => mSlot;

	/// Whether `g` is the gadget this one holds.
	[Scriptable]
	public bool Holds(Gadget g)
	{
		SawNull = g == null;
		return (g != null) && (g === Other);
	}

	public ScriptWeakRef TakeScriptWeak() => (mTable != null) ? ScriptWeakRef(mTable, mSlot, mGeneration) : default;
}

/// A weakly held class derived from another: its family's root is Gadget, so
/// `Sprocket::Of(gadget)` narrows to it.
[Scriptable]
class Sprocket : Gadget
{
	[Scriptable]
	public int Teeth = 12;

	public this(FakeWeakTable table) : base(table) {}
}

/// Another of Gadget's family, so a narrowing to the wrong one has something to miss.
[Scriptable]
class Gizmo : Gadget
{
	public this(FakeWeakTable table) : base(table) {}
}
