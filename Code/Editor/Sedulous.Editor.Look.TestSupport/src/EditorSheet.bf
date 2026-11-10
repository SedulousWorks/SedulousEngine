using System;
using Sedulous.Core.IO;
using Sedulous.Fonts.TrueType;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Look;

namespace Sedulous.Editor.Look.TestSupport;

/// The editor's own sheet (the default density's) as EditorLookHost makes it, from the
/// repository's Data, for a test whose behaviour only the sheet shows (the sizes it gives, the
/// bars it holds). Deleted while the tree it styled is there: its styles go first, the files they
/// read and the fonts they chose after.
public class EditorSheet
{
	public EditorResources Resources ~ delete _;
	/// The sheet's faces (its @font-face), as the host loads them; null without `withFonts`,
	/// when no label has a font and text measures nothing (a test of padding needs none).
	public TrueTypeFontService Fonts ~ delete _;
	public StyleManager Styles;
	private String mDataRoot = new .() ~ delete _;

	public this(bool withFonts = false)
	{
		Test.Assert(EditorData.Root(mDataRoot), "the repository's Data is found");
		Resources = new .(mDataRoot, EditorLookHost.cEditorFolder); // the editor's folder alone, as the host watches
		let look = scope EditorLook();
		look.Density.Set("default");
		let text = EditorLookHost.SheetFor(Resources, look, .. scope String());
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, EditorLookHost.cSheetPath, sheet);
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
	/// host bakes it with (EditorLookHost.FaceOptions).
	private bool LoadFontFace(StringView face, StringView source)
	{
		let loaded = Fonts.LoadFont(face, PathJoin(mDataRoot, source, .. scope String()), EditorLookHost.FaceOptions()) == .Success;
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

/// The repository's Data, as a test reads the editor's files from it.
public static class EditorData
{
	/// The data root found from the test's executable or working directory (the checkout's Data,
	/// by its marker); false when there is none.
	public static bool Root(String outPath)
	{
		FindDataRoot(outPath);
		return !outPath.IsEmpty;
	}

	/// A page's or a dialog's markup read from the repository's Data with the GUI's elements, as
	/// the host reads it; its one reference the caller's.
	public static Node LoadMarkup(StringView path)
	{
		let data = scope String();
		Test.Assert(Root(data), "the repository's Data is found");
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), text) case .Ok, scope String(path));
		RegisterGuiElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}
}
