using System;
using Sedulous.Engine.UI;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI.Tests;

/// The editor preview seam: a document instantiated through the GAME context, so it gets the
/// game's fonts and styles, into a root the overlay roles never draw.
class UIPreviewTests
{
	[Test]
	public static void PreviewRootsLiveInTheContextButNeverOnTheScreenRoot()
	{
		let fixture = scope UITestFixture();

		// A parse failure gives null, so an editor page keeps its last good preview.
		let bad = scope UIDocument();
		bad.Markup.Set("<NoSuchControl>");
		Test.Assert(fixture.UI.CreatePreview(bad) == null);

		let good = scope UIDocument();
		good.Markup.Set("<FlexLayout><Label id=\"pv\" text=\"preview\" /></FlexLayout>");
		// The CALLER owns what comes back; destroying it only detaches.
		let preview = fixture.UI.CreatePreview(good);
		Test.Assert(preview != null);

		// The document instantiated under the preview root...
		Test.Assert(preview.ChildCount == 1);
		Test.Assert(preview.FindByName("pv") != null);

		// ...which is NOT parented to the screen root, since the overlay roles draw only
		// the screen root and a preview can therefore never leak into a game target...
		let screenChildren = fixture.UI.ScreenRoot.ChildCount;
		Test.Assert(fixture.UI.ScreenRoot.FindByName("pv") == null);

		// ...and frames tick without disturbing the screen tier.
		fixture.Frame();
		Test.Assert(fixture.UI.ScreenRoot.ChildCount == screenChildren);

		fixture.UI.DestroyPreview(preview);
		fixture.Frame();
		preview.ReleaseRef();
	}
}
