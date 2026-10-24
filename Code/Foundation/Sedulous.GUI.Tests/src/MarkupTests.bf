using System;
using Sedulous.Core.Logging;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// MarkupLoader: inflate a widget tree from XML - element to widget, nesting to children, id and
/// class to identity, claimed attributes (text) structural, and everything else applied as inline
/// CSS through the StyleApplier.
class MarkupTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void InflatesANestedTreeWithIdentityAndStructuralAttributes()
	{
		let root = MarkupFixtures.Load(
			"<Panel flex-direction=\"row\" gap=\"6\" id=\"root\">\n" +
			"    <Label text=\"Title\" text-align=\"center\"/>\n" +
			"    <Button text=\"OK\" class=\"accent primary\"/>\n" +
			"</Panel>");
		Test.Assert(root != null);
		defer root.ReleaseRef();

		let layout = root as Panel;
		Test.Assert(layout != null);
		Test.Assert(layout.Id == "root");
		Test.Assert(layout.LayoutStyle.Direction == .Row);
		Test.Assert(Near(layout.LayoutStyle.ColumnGap, 6.0f));
		Test.Assert(layout.ChildCount == 2);

		let title = layout.GetChildAt(0) as Label;
		Test.Assert(title != null);
		Test.Assert(title.Text == "Title");
		Test.Assert(title.TextAlignH == .Center);

		let button = layout.GetChildAt(1) as Button;
		Test.Assert(button != null);
		Test.Assert(button.Text == "OK");
		Test.Assert(button.HasClass("accent"));
		Test.Assert(button.HasClass("primary"));
	}

	[Test]
	public static void UnclaimedAttributesAreAppliedAsInlineCss()
	{
		let root = MarkupFixtures.Load("<Label text=\"Hi\" width=\"120\" height=\"30\" background-color=\"#ff0000\" padding=\"4\"/>");
		Test.Assert(root != null);
		defer root.ReleaseRef();
		let label = root as Label;
		Test.Assert(label != null);
		label.UpdateLayout();

		Test.Assert(Near(label.Size.X, 120.0f));
		Test.Assert(Near(label.Size.Y, 30.0f));
		Test.Assert(Near(label.Padding.Left, 4.0f));
		Test.Assert(Near(label.Box.BackgroundColor.R, 1.0f));
	}

	[Test]
	public static void CssLengthUnitsWorkInMarkupThroughTheApplier()
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		var ctx = LengthContext();
		ctx.RootFontSize = 10.0f; // 2rem -> 20
		let loader = scope MarkupLoader(elements, null, null, ctx);
		let root = loader.LoadFromString("<Button width=\"2rem\"/>");
		Test.Assert(root != null);
		defer root.ReleaseRef();
		root.UpdateLayout();
		Test.Assert(Near((root as Button).Size.X, 20.0f));
	}

	[Test]
	public static void AnUnknownRootElementYieldsNullUnknownChildrenAreSkipped()
	{
		Test.Assert(MarkupFixtures.Load("<NotAWidget/>") == null);

		let root = MarkupFixtures.Load("<Panel><Label text=\"a\"/><Bogus/><Label text=\"b\"/></Panel>");
		Test.Assert(root != null);
		defer root.ReleaseRef();
		Test.Assert(root.ChildCount == 2); // the <Bogus/> child was skipped
	}

	[Test]
	public static void AParseErrorYieldsNull()
	{
		Test.Assert(MarkupFixtures.Load("<Panel><Label text=\"x\"") == null); // unterminated
	}

	[Test]
	public static void NameBindsToTheGUIsDataModelTwoWayWhereTheUserChangesIt()
	{
		RegisterGuiElements();
		let scene = SceneFixtures.NewScene();
		defer scene.ReleaseRef();
		let data = scene.Context.Data;
		data.Set("score", System.Variant.Create((int32)7));
		data.Set("volume", System.Variant.Create(0.5));
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		loader.SetDataModel(scene.Context.Data);
		let tree = loader.LoadFromString(
			"<Panel>\n" +
			"    <Label text=\"Score: {{ score }} of {{max}}\"/>\n" +
			"    <Slider value=\"{{volume}}\"/>\n" +
			"    <Label text=\"{{volume}}\"/>\n" +
			"    <Label text=\"{{unclosed\"/>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		scene.AddChild(tree);
		let score = tree.GetChildAt(0) as Label;
		let slider = tree.GetChildAt(1) as Slider;
		let volume = tree.GetChildAt(2) as Label;
		let literal = tree.GetChildAt(3) as Label;
		Test.Assert((score != null) && (slider != null) && (volume != null) && (literal != null));
		Test.Assert(score.Text == "Score: 7 of "); // max unset: empty, and followed
		Test.Assert(Near((float)slider.Value, 0.5f));
		Test.Assert(volume.Text == "0.5");
		Test.Assert(literal.Text == "{{unclosed"); // malformed: as written
		Test.Assert(volume.BindingCount == 1); // a label's text does not write back

		data.Set("max", System.Variant.Create((int32)10));
		slider.Value = 0.25; // the user drags it
		scene.Context.Update(SceneFixtures.Frame); // the write-back's followers run in the same flush
		Test.Assert(score.Text == "Score: 7 of 10");
		Test.Assert(volume.Text == "0.25");
	}

	[Test]
	public static void WidgetPropertiesReflectedWithCssNamesAreMarkupAttributes()
	{
		let tree = MarkupFixtures.Load(
			"<Panel>\n" +
			"    <TextField placeholder=\"Your name\" max-length=\"12\" tooltip=\"Who are you?\"/>\n" +
			"    <Panel display=\"grid\" grid-template-columns=\"1fr 1fr 1fr\" gap=\"6\"/>\n" +
			"    <ScrollView/>\n" +
			"    <ComboBox items=\"Apple | Banana|Cherry\"/>\n" +
			"    <ListBox items=\"One|Two\"/>\n" +
			"    <Window title=\"Tools\"/>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert(tree.ChildCount == 6);
		let field = tree.GetChildAt(0) as TextField;
		Test.Assert(field != null);
		Test.Assert(field.Placeholder == "Your name");
		Test.Assert(field.MaxLength == 12); // a whole number, converted from the attribute's text
		Test.Assert(field.TooltipText == "Who are you?");
		let grid = tree.GetChildAt(1) as Panel; // layout attributes are inline CSS
		Test.Assert(grid != null);
		Test.Assert(grid.LayoutStyle.Kind == .Grid);
		Test.Assert(grid.LayoutStyle.Columns.Count == 3);
		Test.Assert(Near(grid.LayoutStyle.RowGap, 6.0f));
		Test.Assert((tree.GetChildAt(2) as ScrollView).IsScrollContainer);
		let combo = tree.GetChildAt(3) as ComboBox; // creatable by tag now
		Test.Assert(combo != null);
		Test.Assert(combo.ItemCount == 3);
		Test.Assert(combo.ItemsText == "Apple|Banana|Cherry");
		Test.Assert((tree.GetChildAt(4) as ListBox).GetItem(1) == "Two");
		Test.Assert((tree.GetChildAt(5) as Window).Title == "Tools");
	}

	[Test]
	public static void AScrollersAndAWindowsChildrenAreTheirContent()
	{
		let tree = MarkupFixtures.Load(
			"<Panel>\n" +
			"    <ScrollView><Label text=\"scrolled\"/></ScrollView>\n" +
			"    <Window><Label text=\"inside\"/></Window>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let scroll = tree.GetChildAt(0) as ScrollView;
		let window = tree.GetChildAt(1) as Window;
		Test.Assert((scroll != null) && (window != null));
		Test.Assert(scroll.ChildCount == 1);
		Test.Assert((scroll.GetChildAt(0) as Label).Text == "scrolled");
		Test.Assert(window.Content.ChildCount == 1);
	}

	[Test]
	public static void TheTextWidgetsPasswordFilterLengthAndRowsAreAttributesAndRichTextAnElement()
	{
		let tree = MarkupFixtures.Load(
			"<Panel>\n" +
			"    <TextField password=\"true\" input-filter=\"digits\" max-length=\"4\"/>\n" +
			"    <TextArea rows=\"6\" read-only=\"true\"/>\n" +
			"    <RichText text=\"[b]bold[/b]\"/>\n" +
			"</Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let field = tree.GetChildAt(0) as TextField;
		Test.Assert(field != null);
		Test.Assert(field.IsPassword);
		Test.Assert(field.InputFilterName == "digits");
		Test.Assert(field.MaxLength == 4);
		let area = tree.GetChildAt(1) as TextArea;
		Test.Assert(area != null);
		Test.Assert(area.Rows == 6);
		Test.Assert(area.IsReadOnly);
		let rich = tree.GetChildAt(2) as RichText;
		Test.Assert(rich != null);
		Test.Assert(rich.Rich);
		Test.Assert(rich.GetTextLayout().Document.Runs[0].Bold);
	}

	[Test]
	public static void AScrollerMayStickToItsEnd()
	{
		let root = MarkupFixtures.Load("<ScrollView stick-to-end=\"true\"/>");
		Test.Assert(root != null);
		defer root.ReleaseRef();
		Test.Assert(root.StickToEnd);
	}

	[Test]
	public static void AnElementOrAnAttributeNothingTakesIsSaidNotDroppedInSilence()
	{
		// The GUI's warnings, kept for the test to read.
		let ring = scope RingLogger(32, .Warning);
		bool previousOwned = false;
		let previous = DetachGlobalLogger(out previousOwned);
		InitGlobalLogger(ring);
		RegisterGuiElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		let page = loader.LoadFromString(
			"<Panel padding=\"4\" border=\"1px solid #fff\" auto-translate=\"off\" colour=\"red\"><Lable text=\"x\"/></Panel>");
		bool ringOwned = false;
		DetachGlobalLogger(out ringOwned); // the ring is the test's
		InitGlobalLogger(previous, previousOwned);
		Test.Assert(page != null);
		defer page.ReleaseRef();
		int lines = 0;
		bool colour = false;
		bool lable = false;
		for (int i = 0; i < ring.Count; i++)
		{
			let line = ring.GetMessage(i, .. scope String());
			if (!MarkupFixtures.Has(line, "GUI:"))
				continue;
			lines++;
			colour = colour || MarkupFixtures.Has(line, "colour");
			lable = lable || MarkupFixtures.Has(line, "Lable");
		}
		Test.Assert(lines == 2); // colour, and <Lable>; the style property, the shorthand and the reflected one pass
		Test.Assert(colour);
		Test.Assert(lable);
	}
}
