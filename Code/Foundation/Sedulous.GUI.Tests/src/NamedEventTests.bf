using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Named events: an event a library names for itself (a gamekit screen's `screenenter`), sent to a
/// node with a detail, heard by name and by no other.
class NamedEventTests
{
	[Test]
	public static void NamedEventsAreHeardByTheirNameOnlyWithTheirDetailATokenRemovesTheListener()
	{
		let node = new UIWidget();
		defer node.ReleaseRef();
		let heard = scope String();
		int others = 0;
		let token = node.AddNamedListener("screenenter", new [&](e) => { heard.Set(((NamedEvent)e).Detail); });
		node.AddNamedListener("screenleave", new [&](e) => { others++; });
		node.SendNamedEvent("screenenter", "title");
		Test.Assert(heard == "title");
		Test.Assert(others == 0);
		Test.Assert(node.RemoveEventListener(token));
		node.SendNamedEvent("screenenter", "again");
		Test.Assert(heard == "title");
	}
}
