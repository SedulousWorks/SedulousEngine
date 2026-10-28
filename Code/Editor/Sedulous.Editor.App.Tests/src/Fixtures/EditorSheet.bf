using System;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor's own sheet (the default density's) as the window makes it, from the repository's
/// Data, for a test whose behaviour only the sheet shows (the sizes it gives, the bars it holds).
/// Deleted while the tree it styled is there: its styles go first, the files they read after.
class EditorSheet
{
	public Sedulous.Editor.Core.EditorResources Resources ~ delete _;
	public StyleManager Styles;

	public this()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		Resources = new .(data);
		let look = scope EditorLook();
		look.Density.Set("default");
		let text = EditorWindow.SheetFor(Resources, look, .. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, EditorWindow.cSheetPath, sheet);
		Styles = new .(sheet);
		Styles.ResourceProvider = Resources; // its @import of the tokens
	}

	public ~this()
	{
		DeleteAndNullify!(Styles);
	}

	/// Styles `root`'s tree, then lays it out (the root's own pass, which places its popups too).
	public void Apply(SceneRoot root)
	{
		Styles.ApplyTree(root);
		root.UpdateLayout();
	}
}
