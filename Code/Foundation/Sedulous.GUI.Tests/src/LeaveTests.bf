using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Leaving: a node that goes plays its way out first, out of input at once.
class LeaveTests
{
	[Test]
	public static void InAGUINoStylePassRunsOverItGoesAtTheNextUpdateNeverInsideTheEventThatSentItDetachedAtOnce()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let widget = new UIWidget();
		defer widget.ReleaseRef();
		root.AddChild(widget);
		widget.Leave();
		Test.Assert(widget.Parent == root); // a click handler that closed it still finds it there
		Test.Assert(widget.IsLeaving);
		root.Context.Update(TimeSpan(0));
		Test.Assert(widget.Parent == null);
		Test.Assert(!widget.IsLeaving);

		let parent = new UIWidget();
		defer parent.ReleaseRef();
		let child = new UIWidget();
		defer child.ReleaseRef();
		parent.AddChild(child);
		child.Leave();
		Test.Assert(child.Parent == null);
	}
}
