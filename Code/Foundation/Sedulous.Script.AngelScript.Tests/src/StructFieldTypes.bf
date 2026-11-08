using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript.Tests.Values;

// Struct-valued fields for StructFieldTests, on a surface of their own so the fixture's
// counts stay as they are.

/// The struct inside a struct.
[Scriptable(.AllPublic)]
struct Door
{
	public float Width;
}

/// A struct with a struct field.
[Scriptable(.AllPublic)]
struct Room
{
	public float Size;
	public Door Entry;
}

/// The owner of two struct fields, one writable and one not.
[Scriptable]
class House
{
	[Scriptable]
	public Room Spare;
	/// Published read only: a script reads it and never writes it.
	[Scriptable, ReadOnly]
	public Room Shown;
}

/// The composition root for these types.
static class ValuesSurface
{
	[OnCompile(.TypeInit), Comptime]
	private static void Generate()
	{
		ScriptSurfaceWalker.Emit(typeof(Self), scope StringView[]("Sedulous.Script.AngelScript.Tests.Values"),
			scope StringView[](ScriptDomains.Runtime));
	}
}
