using System;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Help > About: the box shows the engine's name and the build's identity, and Copy Version hands
/// that line to the clipboard's caller; OK copies nothing.
class AboutBoxTests
{
	[Test]
	public static void CopyVersionHandsOverTheEnginesNameAndTheBuildsIdentityOkCopiesNothing()
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(900.0f, 700.0f);
		StringView identity = "0.1.0-beta (build 3, 2026-11-05T15:03:00Z)";
		let line = AboutBox.Line(identity, .. scope .());
		Test.Assert(line == scope String()..AppendF("{} 0.1.0-beta (build 3, 2026-11-05T15:03:00Z)", EngineVersion.ProductName));

		let copied = scope String();
		int copies = 0;
		let about = AboutBox.Make(identity, new [&copied, &copies] (text) =>
			{
				copied.Set(text);
				copies++;
			});
		defer about.ReleaseRef();
		Test.Assert(about.Title == scope String()..AppendF("About {}", EngineVersion.ProductName));
		Test.Assert(about.Message == line);
		about.OpenModal(root);
		Test.Assert(about.IsOpen);
		Test.Assert(about.ButtonCount == 2, "OK, then Copy Version");
		Test.Assert(about.ButtonAt(1).Text == "Copy Version");
		Test.Assert(about.ButtonAt(1).HandleActivate());
		Test.Assert(copies == 1);
		Test.Assert(copied == line);
		Test.Assert(!about.IsOpen);

		let again = AboutBox.Make(identity, new [&copies] (text) => { copies++; });
		defer again.ReleaseRef();
		again.OpenModal(root);
		Test.Assert(again.ButtonAt(0).HandleActivate()); // OK
		Test.Assert(copies == 1);
		Test.Assert(!again.IsOpen);

		// No copy given: Copy Version only closes the box.
		let none = AboutBox.Make(identity, null);
		defer none.ReleaseRef();
		none.OpenModal(root);
		Test.Assert(none.ButtonAt(1).HandleActivate());
		Test.Assert(!none.IsOpen);
	}
}
