using System;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Fixture;

/// A class derived from another on the surface: its handle reaches Thing's instance members as
/// well as its own, and its own Label hides Thing's.
[Scriptable]
class SpecialThing : Thing
{
	[Scriptable]
	public int Extra = 11;

	[Scriptable]
	public new StringView Label() => "special";
}
