namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class ControlStateTests
{
	[Test]
	public static void Normal_IsZero()
	{
		let state = ControlState.Normal;
		Test.Assert((int)state == 0);
	}

	[Test]
	public static void SingleFlags()
	{
		Test.Assert(ControlState.Hover.HasFlag(.Hover));
		Test.Assert(!ControlState.Hover.HasFlag(.Pressed));
		Test.Assert(ControlState.Disabled.HasFlag(.Disabled));
		Test.Assert(ControlState.Checked.HasFlag(.Checked));
	}

	[Test]
	public static void CompoundFlags()
	{
		let state = ControlState.Checked | .Hover;
		Test.Assert(state.HasFlag(.Checked));
		Test.Assert(state.HasFlag(.Hover));
		Test.Assert(!state.HasFlag(.Pressed));
		Test.Assert(!state.HasFlag(.Disabled));
	}

	[Test]
	public static void AllFlags_Combinable()
	{
		let state = ControlState.Hover | .Pressed | .Focused | .Disabled | .Checked | .Indeterminate;
		Test.Assert(state.HasFlag(.Hover));
		Test.Assert(state.HasFlag(.Pressed));
		Test.Assert(state.HasFlag(.Focused));
		Test.Assert(state.HasFlag(.Disabled));
		Test.Assert(state.HasFlag(.Checked));
		Test.Assert(state.HasFlag(.Indeterminate));
	}

	[Test]
	public static void CheckedHover_Compound()
	{
		// Simulates a checked checkbox being hovered
		let state = ControlState.Checked | .Hover;
		Test.Assert(state != .Checked);
		Test.Assert(state != .Hover);
		Test.Assert(state.HasFlag(.Checked));
		Test.Assert(state.HasFlag(.Hover));
	}
}
