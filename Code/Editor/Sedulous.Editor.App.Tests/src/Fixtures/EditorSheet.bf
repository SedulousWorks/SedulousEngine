using System;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor's own sheet (the default density's) as the window makes it, from the repository's
/// Data, for a test whose behaviour only the sheet shows (the sizes it gives, the bars it holds).
/// Deleted while the tree it styled is there: its styles go first, the files they read and the
/// fonts they chose after.
class EditorSheet
{
	public Sedulous.Editor.Core.EditorResources Resources ~ delete _;
	/// The sheet's faces (its @font-face), as the window loads them; null without `withFonts`,
	/// when no label has a font and text measures nothing (a test of padding needs none).
	public TrueTypeFontService Fonts ~ delete _;
	public StyleManager Styles;
	private String mDataRoot = new .() ~ delete _;

	public this(bool withFonts = false)
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		mDataRoot.Set(data);
		Resources = new .(data);
		let look = scope EditorLook();
		look.Density.Set("default");
		let text = EditorWindow.SheetFor(Resources, look, .. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, EditorWindow.cSheetPath, sheet);
		Styles = new .(sheet);
		Styles.ResourceProvider = Resources; // its @import of the tokens
		if (withFonts)
		{
			Fonts = new .();
			Styles.FontService = Fonts;
			Styles.SetFontFaceLoader(new (face, source) => LoadFontFace(face, source));
		}
	}

	public ~this()
	{
		DeleteAndNullify!(Styles);
	}

	/// A face the sheet's @font-face names, from its file under the data root, at the options the
	/// window's EditorWindow.LoadFontFace bakes it with.
	private bool LoadFontFace(StringView face, StringView source)
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = 16.0f;
		options.LastCodepoint = 0x17F;
		let loaded = Fonts.LoadFont(face, PathJoin(mDataRoot, source, .. scope String()), options) == .Success;
		Test.Assert(loaded, scope $"the @font-face {face} ({source}) loads");
		return loaded;
	}

	/// Styles `root`'s tree, then lays it out (the root's own pass, which places its popups too).
	public void Apply(SceneRoot root)
	{
		Styles.ApplyTree(root);
		root.UpdateLayout();
	}
}
