using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget that keeps the template markup gives it.
[GuiReflect(true, "test:Templated")]
class TemplateProbe : UIWidget
{
	public String TemplateType = new .() ~ delete _;
	public String TemplateMarkup = new .() ~ delete _;

	public override bool SetMarkupTemplate(StringView type, StringView markup)
	{
		TemplateType.Set(type);
		TemplateMarkup.Set(markup);
		return true;
	}
}

/// The loader's tiers beyond the ported cases: nested tags to a tree (through a widget's child
/// host), a reflected property reached by its CSS name and by its own name, what it drops said with
/// the line it is on, identity and inline style, a binding both ways, a translation following the
/// tables, a template kept as markup and an item's attributes recorded for its row.
class MarkupLoaderTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void NestedTagsBecomeATreeInOrderAWidgetsChildHostTakingItsChildren()
	{
		let tree = MarkupFixtures.Load(
			"<Panel id=\"top\">\n" +
			"    <Panel id=\"left\"><Label id=\"a\"/><Label id=\"b\"/></Panel>\n" +
			"    <Expander id=\"more\"><Panel id=\"deep\"><Button id=\"c\"/></Panel></Expander>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert(tree.ChildCount == 2);
		let left = tree.GetChildAt(0) as Panel;
		Test.Assert((left != null) && (left.Id == "left"));
		Test.Assert(left.ChildCount == 2);
		Test.Assert((left.GetChildAt(0) as Label).Id == "a");
		Test.Assert((left.GetChildAt(1) as Label).Id == "b");
		let more = tree.GetChildAt(1) as Expander;
		Test.Assert(more != null);
		Test.Assert(more.Content.ChildCount == 1); // into its content, not beside its header
		let deep = more.Content.GetChildAt(0) as Panel;
		Test.Assert((deep != null) && (deep.Id == "deep"));
		Test.Assert(deep.GetChildAt(0) is Button);
		Test.Assert(MarkupFixtures.Find(tree, "c").Parent == deep);
	}

	[Test]
	public static void AReflectedPropertyIsReachedByItsCssNameAndInABindingByItsOwnNameInAnyCase()
	{
		RegisterGuiElements();
		let scene = SceneFixtures.NewScene();
		defer scene.ReleaseRef();
		scene.Context.Data.Set("n", System.Variant.Create((int32)7));
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		loader.SetDataModel(scene.Context.Data);
		let tree = loader.LoadFromString(
			"<Panel>\n" +
			"    <TextField max-length=\"5\"/>\n" +
			"    <TextField max-length=\"{{n}}\"/>\n" +
			"    <TextField maxLength=\"{{n}}\"/>\n" +
			"    <TextField MaxLength=\"{{n}}\"/>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert((tree.GetChildAt(0) as TextField).MaxLength == 5); // its CSS name, as inline CSS
		Test.Assert((tree.GetChildAt(1) as TextField).MaxLength == 7); // bound by its CSS name
		Test.Assert((tree.GetChildAt(2) as TextField).MaxLength == 7); // by its own name, any case
		Test.Assert((tree.GetChildAt(3) as TextField).MaxLength == 7);
		scene.Context.Data.Set("n", System.Variant.Create((int32)9));
		Test.Assert((tree.GetChildAt(2) as TextField).MaxLength == 9); // detached: at once
	}

	[Test]
	public static void AnUnknownTagAndAnUnknownAttributeAreSaidWithTheirLines()
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let loader = scope MarkupLoader(elements);
		loader.SetDiagnostics(said);
		let tree = loader.LoadFromString(
			"<Panel>\n" +
			"\n" +
			"  <Nope><Label/></Nope>\n" +
			"  <Label\n" +
			"    text=\"a\"\n" +
			"    bogus=\"1\"/>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert(tree.ChildCount == 1); // <Nope> and the label in it left out
		Test.Assert(said.Count == 2);
		bool nope = false;
		bool bogus = false;
		for (let d in said)
		{
			Test.Assert(d.Level == .Warning);
			if (MarkupFixtures.Has(d.Message, "<Nope>"))
			{
				nope = true;
				Test.Assert(d.Line == 3);
			}
			else if (MarkupFixtures.Has(d.Message, "'bogus'"))
			{
				bogus = true;
				Test.Assert(d.Line == 6);
				Test.Assert(MarkupFixtures.Has(d.Message, "<Label>"));
			}
		}
		Test.Assert(nope && bogus);
	}

	[Test]
	public static void IdAndClassSetIdentityStyleAttributesAreKeptAsTheNodesInlineStyle()
	{
		let tree = MarkupFixtures.Load("<Label id=\"name\" class=\" one\ttwo\nthree \" opacity=\"0.5\" padding=\"3\" rich=\"true\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let label = tree as Label;
		Test.Assert(label.Id == "name");
		Test.Assert(label.HasClass("one"));
		Test.Assert(label.HasClass("two"));
		Test.Assert(label.HasClass("three"));
		Test.Assert(!label.HasClass(""));
		Test.Assert(Near(label.Alpha, 0.5f)); // applied as it loads
		Test.Assert(Near(label.Padding.Left, 3.0f));
		Test.Assert(label.Rich); // claimed by the label: not inline style
		Test.Assert(label.InlineStyle.Length == 2); // opacity and padding; id, class and rich are none
		Test.Assert(label.InlineStyle[0].Name == "opacity");
		Test.Assert(label.InlineStyle[0].Value == "0.5");
		Test.Assert(label.InlineStyle[1].Name == "padding");
	}

	[Test]
	public static void AnAttributeNoWidgetClaimsFallsThroughToInlineCssAsApplyAttributeDoes()
	{
		let tree = MarkupFixtures.Load("<Panel text=\"words\" opacity=\"0.25\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let panel = tree as Panel;
		Test.Assert(Near(panel.Alpha, 0.25f));
		bool text = false;
		for (let d in panel.InlineStyle)
			text = text || ((d.Name == "text") && (d.Value == "words")); // a panel has no text: kept as CSS
		Test.Assert(text);

		let label = new Label();
		defer label.ReleaseRef();
		MarkupLoader.ApplyAttribute(label, "text", "Bo"); // the label's own
		MarkupLoader.ApplyAttribute(label, "opacity", "0.5"); // inline, for the style pass
		Test.Assert(label.Text == "Bo");
		Test.Assert(label.InlineStyle.Length == 1);
		Test.Assert(label.InlineStyle[0].Name == "opacity");
	}

	[Test]
	public static void ABindingToATwoWayPropertyFollowsTheDataAndWritesTheUsersChangeBack()
	{
		RegisterGuiElements();
		let scene = SceneFixtures.NewScene();
		defer scene.ReleaseRef();
		let data = scene.Context.Data;
		data.Set("on", System.Variant.Create(true));
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		loader.SetDataModel(data);
		let tree = loader.LoadFromString("<CheckBox checked=\"{{on}}\" text=\"Sound\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		scene.AddChild(tree);
		let @box = tree as CheckBox;
		Test.Assert(@box.Checked);
		Test.Assert(@box.BindingCount == 2); // the value, and its write-back

		@box.Toggle(); // as a click does
		scene.Context.Update(SceneFixtures.Frame);
		Test.Assert(data.Get("on").VariantType == typeof(bool));
		Test.Assert(!data.Get("on").Get<bool>());

		data.Set("on", System.Variant.Create(true)); // the game sets it
		scene.Context.Update(SceneFixtures.Frame);
		Test.Assert(@box.Checked);
	}

	[Test]
	public static void ATranslatedAttributeFollowsTheTablesItResolvesThrough()
	{
		let texts = scope TranslationTexts();
		let bed = scope TranslationBed();
		bed.Root.Context.Localization = texts.Loc;
		defer { bed.Root.Context.Localization = null; }
		let page = bed.Load("<Label text=\"@menu.play\"/>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		bed.Root.AddChild(page);
		bed.Step();
		let label = page as Label;
		Test.Assert(label.Text == "Play");
		Test.Assert(label.TranslationKey("Text") == "menu.play");

		let over = scope Sedulous.I18N.StringTable();
		Test.Assert(over.Set("menu.play", "en", "Start"));
		texts.Loc.AddTable(over); // the last added wins
		bed.Step();
		Test.Assert(label.Text == "Start");
		texts.Loc.RemoveTable(over);
		bed.Step();
		Test.Assert(label.Text == "Play");
	}

	[Test]
	public static void ATemplateIsKeptAsMarkupByItsParentAndItemAttributesAreRecordedForTheRow()
	{
		RegisterGuiElements();
		Test.Assert(ElementTypes.Register(TemplateProbe.StaticGuiType));
		defer ElementTypes.Unregister(TemplateProbe.StaticGuiType);
		let probe = MarkupFixtures.Load(
			"<test:Templated><template type=\"row\"><Label text=\"{{item.Name}}\"/></template><Label text=\"kept\"/></test:Templated>");
		Test.Assert(probe != null);
		defer probe.ReleaseRef();
		let templated = probe as TemplateProbe;
		Test.Assert(templated.ChildCount == 1); // the template is no child
		Test.Assert((templated.GetChildAt(0) as Label).Text == "kept");
		Test.Assert(templated.TemplateType == "row");
		Test.Assert(MarkupFixtures.Has(templated.TemplateMarkup, "<Label"));
		Test.Assert(MarkupFixtures.Has(templated.TemplateMarkup, "{{item.Name}}"));

		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		let bindings = scope List<ItemBinding>();
		defer { ClearAndDeleteItems!(bindings); }
		loader.SetItemBindings(bindings);
		let row = loader.LoadFromString("<Panel><Label text=\"{{item.Name}}\"/><Label text=\"#{{ index }}\"/><Label text=\"plain\"/></Panel>");
		Test.Assert(row != null);
		defer row.ReleaseRef();
		Test.Assert(bindings.Count == 2);
		Test.Assert(bindings[0].Target == row.GetChildAt(0));
		Test.Assert(bindings[0].Attribute == "text");
		Test.Assert(bindings[0].Parts.Count == 1);
		Test.Assert(bindings[0].Parts[0].IsName && (bindings[0].Parts[0].Text == "item.Name"));
		Test.Assert(bindings[1].Parts.Count == 2);
		Test.Assert(!bindings[1].Parts[0].IsName && (bindings[1].Parts[0].Text == "#"));
		Test.Assert(bindings[1].Parts[1].IsName && (bindings[1].Parts[1].Text == "index")); // trimmed
		Test.Assert((row.GetChildAt(0) as Label).Text.IsEmpty); // left for the row to fill
		Test.Assert((row.GetChildAt(2) as Label).Text == "plain");
	}
}
