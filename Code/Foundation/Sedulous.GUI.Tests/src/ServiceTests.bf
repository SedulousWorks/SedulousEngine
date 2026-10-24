using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Services a library finds through its GUI (the gamekit's InputPrompts): set, replaced and
/// cleared by key, borrowed, and followed by bindings.
class ServiceTests
{
	[Test]
	public static void SetReplacedAndClearedByKeyABindingThatReadOneRunsAgainWhenItChanges()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let gui = root.Context;
		int first = 1;
		int second = 2;
		Test.Assert(gui.GetService("test.thing") == null);
		let node = new UIWidget();
		defer node.ReleaseRef();
		root.AddChild(node);
		int seen = 0;
		node.Bind(new [&]() =>
			{
				let thing = (int*)gui.GetService("test.thing");
				seen = (thing != null) ? *thing : 0;
			});
		gui.SetService("test.thing", &first);
		gui.Update(TimeSpan(0));
		Test.Assert(seen == 1);
		gui.SetService("test.thing", &second);
		gui.Update(TimeSpan(0));
		Test.Assert(seen == 2);
		Test.Assert(gui.GetService("test.other") == null);
		gui.SetService("test.thing", null);
		gui.Update(TimeSpan(0));
		Test.Assert(seen == 0);
	}
}
