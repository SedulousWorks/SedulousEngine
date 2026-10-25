using System;
using Sedulous.Core;

namespace Sedulous.Script.Fixture;

/// A class scripts hold by a counted reference, as the GUI's tweens are: a script may make
/// one, a handle it keeps keeps the spool, and the last release frees it. Live counts the
/// spools not yet freed, so a test sees every reference come back.
[Scriptable]
class Spool : RefCounted, IScriptCounted
{
	/// Observed by the tests: the spools made and not yet freed.
	public static int Live = 0;

	/// HELD: one reference on the next spool, null when none.
	private Spool mNext = null;

	[Scriptable]
	public int Turns;

	[Scriptable]
	public this()
	{
		Live++;
	}

	public ~this()
	{
		mNext?.ReleaseRef();
		Live--;
	}

	/// The spool after this one, holding a reference: set takes one on the new spool and
	/// drops the old's.
	[Scriptable]
	public Spool Next
	{
		get => mNext;
		set
		{
			value?.AddRef();
			mNext?.ReleaseRef();
			mNext = value;
		}
	}

	/// This spool again, lent: no reference passes with it.
	[Scriptable]
	public Spool Itself() => this;

	/// A new spool whose one reference passes to the caller.
	[Scriptable, ScriptReturnsReference]
	public static Spool Make()
	{
		let made = new Spool();
		made.Turns = 1;
		return made;
	}

	/// Whether `s` is the spool after this one.
	[Scriptable]
	public bool Holds(Spool s) => (s != null) && (s === mNext);
}

/// A counted class derived from another, so a handle to one converts to its base's.
[Scriptable]
class Bobbin : Spool
{
	[Scriptable]
	public int Wraps = 3;

	[Scriptable]
	public this() {}
}
