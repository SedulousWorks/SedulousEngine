using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A face that answers to the family and size it was made for.
class NamedFont : IFont
{
	private String mFamily = new .() ~ delete _;
	private float mSize;

	public this(StringView family, float size)
	{
		mFamily.Set(family);
		mSize = size;
	}

	public override void GetFamilyName(String outName) { outName.Append(mFamily); }
	public override Span<uint8> SourceData => default;
	public override FontMetrics Metrics => .(mSize * 0.8f, -mSize * 0.2f, 0.0f, mSize, 1.0f);
	public override float PixelHeight => mSize;

	public override GlyphInfo GetGlyphInfo(int32 codepoint)
	{
		var g = GlyphInfo();
		g.Codepoint = codepoint;
		g.AdvanceWidth = mSize * 0.5f;
		return g;
	}

	public override float GetKerning(int32 firstCodepoint, int32 secondCodepoint) => 0.0f;
	public override bool HasGlyph(int32 codepoint) => true;
	public override float MeasureString(StringView text) => (float)text.Length * mSize * 0.5f;
	public override float MeasureString(StringView text, List<GlyphPosition> outPositions) => MeasureString(text);
}

/// One cached font per family and size asked for.
class NamedFonts : IFontService
{
	private List<CachedFont> mFonts = new .() ~ DeleteContainerAndItems!(_);

	public override CachedFont GetFont(float pixelHeight) => GetFont("default", pixelHeight);

	public override CachedFont GetFont(StringView familyName, float pixelHeight)
	{
		for (let f in mFonts)
		{
			if ((f.Font.GetFamilyName(.. scope String()) == familyName) && (f.Font.PixelHeight == pixelHeight))
				return f;
		}
		let font = new CachedFont(new NamedFont(familyName, pixelHeight), null);
		mFonts.Add(font);
		return font;
	}

	public override ImageData GetAtlasTexture(CachedFont font) => null;
	public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight) => null;
	public override void ReleaseFont(CachedFont font) { }
	public override void GetDefaultFontFamily(String outFamily) { outFamily.Append("default"); }
	public override bool HasFamily(StringView familyName) => true;
}

/// Inheritance: the text properties pass down through nodes that draw no text (colour, the font,
/// text-align, white-space, line-height, letter-spacing), a declared value wins over them, a
/// parent's change reaches its subtree, and inherit, initial and unset; text-overflow and
/// line-clamp do not inherit.
class InheritanceTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	private static bool Same(Color a, Color b) => (a.R == b.R) && (a.G == b.G) && (a.B == b.B) && (a.A == b.A);

	private static String FamilyOf(CachedFont font, String outName)
	{
		font.Font.GetFamilyName(outName);
		return outName;
	}

	/// A label in a panel in a panel of class `outer`, styled by `css` over named fonts. The root
	/// (and the tree) go with the bed.
	private class Bed
	{
		public NamedFonts Faces = new .() ~ delete _;
		public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
		public Sedulous.GUI.Panel Panel = new .() ~ _.ReleaseRef();
		public Sedulous.GUI.Panel Inner = new .() ~ _.ReleaseRef();
		public Sedulous.GUI.Label Label = new .() ~ _.ReleaseRef();
		public StyleManager Styles = new .() ~ delete _;

		public this(StringView css)
		{
			Root.AddChild(Panel);
			Panel.AddChild(Inner);
			Inner.AddChild(Label);
			Panel.AddClass("outer");
			Styles.FontService = Faces;
			WidgetFixtures.UseSheet(Styles, css);
			Styles.ApplyTree(Root);
		}

		public void Restyle() => Styles.ApplyTree(Root);
	}

	[Test]
	public static void ColourTheFontAndTextAlignPassDownThroughNodesThatDrawNoText()
	{
		let bed = scope Bed(".outer { color: #ff0000; font-family: Serif; font-size: 20px; text-align: center; vertical-align: bottom; }");
		Test.Assert(Same(bed.Label.TextColor, .(1.0f, 0.0f, 0.0f, 1.0f)));
		Test.Assert(bed.Label.Font != null);
		Test.Assert(FamilyOf(bed.Label.Font, scope .()) == "Serif");
		Test.Assert(Near(bed.Label.Font.Font.PixelHeight, 20.0f));
		Test.Assert(bed.Label.TextAlignH == .Center);
		Test.Assert(bed.Label.TextAlignV == .Middle); // vertical-align does not inherit: the label's own
	}

	[Test]
	public static void ADeclaredValueWinsASizeAloneKeepsTheInheritedFamilyAndItAllGoesWhenTheRuleDoes()
	{
		let bed = scope Bed(".outer { color: #ff0000; font-family: Serif; font-size: 20px; } label.big { font-size: 30px; } label.blue { color: #0000ff; }");
		let own = Color.White;
		bed.Label.AddClass("big");
		bed.Label.AddClass("blue");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, .(0.0f, 0.0f, 1.0f, 1.0f)));
		Test.Assert(FamilyOf(bed.Label.Font, scope .()) == "Serif");
		Test.Assert(Near(bed.Label.Font.Font.PixelHeight, 30.0f));

		bed.Label.RemoveClass("blue");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, .(1.0f, 0.0f, 0.0f, 1.0f))); // the parent's again

		bed.Panel.RemoveClass("outer");
		bed.Label.RemoveClass("big");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, own)); // nobody sets it: the label's own
		Test.Assert(bed.Label.Font == null);
	}

	[Test]
	public static void AParentsChangeReachesItsSubtreeFromTheSheetOrFromCode()
	{
		let bed = scope Bed(".outer { color: #ff0000; } .outer.cool { color: #00ffff; }");
		bed.Panel.AddClass("cool");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, .(0.0f, 1.0f, 1.0f, 1.0f)));

		// Code's colour on the middle panel is its own, and the label below takes it.
		bed.Inner.TextColor = .(0.0f, 1.0f, 0.0f, 1.0f);
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, .(0.0f, 1.0f, 0.0f, 1.0f)));
		bed.Panel.RemoveClass("cool");
		bed.Restyle();
		Test.Assert(Same(bed.Inner.TextColor, .(0.0f, 1.0f, 0.0f, 1.0f)));
	}

	[Test]
	public static void InheritInitialAndUnset()
	{
		let bed = scope Bed(".outer { color: #ff0000; padding: 6px; } " +
			"label.mine { color: initial; } " +
			"label.pass { color: unset; } " +
			"panel.copy { padding: inherit; } " +
			"panel.grow { padding: 4px; width: 50px; } panel.grow.reset { width: initial; padding: unset; }");
		bed.Label.AddClass("mine");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, Color.White)); // initial: its own, not the parent's
		bed.Label.RemoveClass("mine");
		bed.Label.AddClass("pass");
		bed.Restyle();
		Test.Assert(Same(bed.Label.TextColor, .(1.0f, 0.0f, 0.0f, 1.0f))); // unset on an inherited property: inherit

		bed.Inner.AddClass("copy");
		bed.Restyle();
		Test.Assert(Near(bed.Inner.Padding.Left, 6.0f)); // inherit on one that does not: the parent's

		bed.Inner.RemoveClass("copy");
		bed.Inner.AddClass("grow");
		bed.Restyle();
		Test.Assert(bed.Inner.LayoutStyle.Width == LayoutLength.Px(50.0f));
		bed.Inner.AddClass("reset");
		bed.Restyle();
		Test.Assert(bed.Inner.LayoutStyle.Width.IsAuto); // initial: the table's (auto)
		Test.Assert(Near(bed.Inner.Padding.Left, 0.0f)); // unset: initial, the node's own
	}

	[Test]
	public static void WhiteSpaceLineHeightAndLetterSpacingPassDownTextOverflowAndLineClampDoNot()
	{
		let bed = scope Bed(".outer { font-family: Serif; font-size: 20px; white-space: pre-wrap; line-height: 1.5; letter-spacing: 2px; " +
			"text-overflow: ellipsis; line-clamp: 2; } " +
			"label.fixed { line-height: 24px; white-space: nowrap; } label.cut { text-overflow: ellipsis-middle; line-clamp: 3; }");
		let text = bed.Label.GetTextStyle();
		Test.Assert(text.WhiteSpace == .PreWrap);
		Test.Assert(text.LineHeightFactor);
		Test.Assert(Near(text.LineHeightPixels, 30.0f)); // 1.5 of its own 20px
		Test.Assert(Near(text.LetterSpacing, 2.0f));
		Test.Assert(bed.Label.TextOverflow == .Clip); // not inherited
		Test.Assert(bed.Label.LineClamp == 0);

		bed.Label.AddClass("fixed");
		bed.Label.AddClass("cut");
		bed.Restyle();
		Test.Assert(bed.Label.GetTextStyle().WhiteSpace == .NoWrap);
		Test.Assert(Near(bed.Label.GetTextStyle().LineHeightPixels, 24.0f));
		Test.Assert(bed.Label.TextOverflow == .EllipsisMiddle);
		Test.Assert(bed.Label.LineClamp == 3);

		bed.Label.RemoveClass("cut");
		bed.Panel.RemoveClass("outer");
		bed.Restyle();
		Test.Assert(bed.Label.TextOverflow == .Clip); // the rule went: its own again
		Test.Assert(bed.Label.LineClamp == 0);
		Test.Assert(Near(bed.Label.GetTextStyle().LetterSpacing, 0.0f));

		// Code's value is code's.
		bed.Label.RemoveClass("fixed");
		bed.Label.WhiteSpace = .Pre;
		bed.Panel.AddClass("outer");
		bed.Restyle();
		Test.Assert(bed.Label.GetTextStyle().WhiteSpace == .Pre);
	}
}
