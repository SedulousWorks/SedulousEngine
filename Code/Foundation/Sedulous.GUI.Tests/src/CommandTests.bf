using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A control that keeps the state its command's binding last told it.
class StateProbe : UIWidget
{
	public bool Available = false;
	public String Reason = new .() ~ delete _;

	public override void OnBoundCommandState(BoundCommandState state)
	{
		base.OnBoundCommandState(state);
		Available = state.Available;
		Reason.Set(state.Reason);
	}
}

/// Commands along a root's focus path, and the controls bound to them.
class CommandTests
{
	[Test]
	public static void ABoundControlHearsWhyItsCommandIsDisabledAndOnlyWhileItIs()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let probe = new StateProbe();
		defer probe.ReleaseRef();
		root.AddChild(probe);
		root.OnCommand("save", new (command) => { });
		let save = root.Context.DefineCommand("save");
		save.DisabledReason = "Nothing to save";
		probe.Command = "save";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Available);
		Test.Assert(probe.Reason.Length == 0); // enabled: the reason is not said

		save.Enabled = false;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		Test.Assert(probe.Reason == "Nothing to save");

		save.DisabledReason = "Read only"; // followed as it changes
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(probe.Reason == "Read only");

		// Unavailable for want of a handler where the focus is: no reason.
		save.Enabled = true;
		probe.Command = "unhandled";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!probe.Available);
		Test.Assert(probe.Reason.Length == 0);
	}
}
