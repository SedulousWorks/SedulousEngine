using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Building a view tree from markup: elements resolve through the registry, and the vocabulary
/// every element shares is the loader's own.
class MarkupLoaderTests
{
	private static void EnsureInit()
	{
		StyleSheetLoader.InitializeGlobals();
		MarkupLoader.Initialize();
	}

	/// Loads markup, or fails the test if it would not load.
	private static View Load(StringView markup, List<String> warnings = null)
	{
		EnsureInit();
		let view = MarkupLoader.LoadFromString(markup, null, warnings);
		Test.Assert(view != null, "the markup did not load");
		return view;
	}

	// ---- Elements -----------------------------------------------------------------------------

	[Test]
	public static void AnElementNameBuildsItsControl()
	{
		let label = Load("<Label text=\"Hello\"/>");
		defer label.ReleaseRef();
		Test.Assert(label is Label);
		Test.Assert((label as Label).Text.Value == "Hello");

		let button = Load("<Button text=\"Click\"/>");
		defer button.ReleaseRef();
		Test.Assert(button is Button);
		Test.Assert((button as Button).Text.Value == "Click");
	}

	/// An element's own text is its `text`, so a button reads the way HTML would write it.
	[Test]
	public static void AnElementsTextContentBecomesItsText()
	{
		let button = Load("<Button>Click Me</Button>");
		defer button.ReleaseRef();

		Test.Assert((button as Button).Text.Value == "Click Me");
	}

	[Test]
	public static void ChildrenNestAndTheTreeIsBuiltDepthFirst()
	{
		let root = Load("""
			<Flex direction="vertical">
				<Label text="A"/>
				<Flex direction="horizontal">
					<Button text="B"/>
					<Button text="C"/>
				</Flex>
			</Flex>
			""");
		defer root.ReleaseRef();

		let outer = root as FlexLayout;
		Test.Assert(outer != null);
		Test.Assert(outer.Direction == .Vertical);
		Test.Assert(outer.ChildCount == 2);

		let inner = outer.GetChildAt(1) as FlexLayout;
		Test.Assert(inner != null);
		Test.Assert(inner.Direction == .Horizontal);
		Test.Assert(inner.ChildCount == 2);
		Test.Assert((inner.GetChildAt(1) as Button).Text.Value == "C");
	}

	/// A layout answers to its short alias as well as its type name.
	[Test]
	public static void ALayoutAnswersToItsAliasAndItsTypeName()
	{
		let shortName = Load("<Flex/>");
		defer shortName.ReleaseRef();
		Test.Assert(shortName is FlexLayout);

		let typeName = Load("<FlexLayout/>");
		defer typeName.ReleaseRef();
		Test.Assert(typeName is FlexLayout);
	}

	[Test]
	public static void AnEmptyContainerLoadsWithNoChildren()
	{
		let flex = Load("<Flex/>");
		defer flex.ReleaseRef();

		Test.Assert((flex as FlexLayout).ChildCount == 0);
	}

	// ---- Failure ------------------------------------------------------------------------------

	[Test]
	public static void UnknownAndUnparseableMarkupAnswersNull()
	{
		EnsureInit();

		Test.Assert(MarkupLoader.LoadFromString("<NotAControl/>") == null);
		Test.Assert(MarkupLoader.LoadFromString("<Flex><unclosed></Flex>") == null);
		Test.Assert(MarkupLoader.LoadFromString("") == null);
	}

	/// An unknown CHILD is dropped rather than failing the load, and reported when a caller
	/// asked to be told.
	[Test]
	public static void AnUnknownChildIsDroppedAndReported()
	{
		let warnings = scope List<String>();
		defer { ClearAndDeleteItems!(warnings); }

		let root = Load("<Flex><Label text=\"A\"/><Nonsense/></Flex>", warnings);
		defer root.ReleaseRef();

		Test.Assert((root as FlexLayout).ChildCount == 1, "the good child survived");
		Test.Assert(warnings.Count == 1);
		Test.Assert(warnings[0].Contains("<Nonsense>"));
	}

	/// The pre-LayoutStyle spelling is NOT quietly aliased: a typo has to be visible, or an
	/// interface silently comes out wrong.
	[Test]
	public static void AnUnknownAttributeIsReportedRatherThanGuessedAt()
	{
		let warnings = scope List<String>();
		defer { ClearAndDeleteItems!(warnings); }

		let root = Load("<Flex><Button text=\"A\" grow=\"1\"/></Flex>", warnings);
		defer root.ReleaseRef();

		Test.Assert(warnings.Count == 1);
		Test.Assert(warnings[0].StartsWith("unknown attribute 'grow'"));

		let child = (root as FlexLayout).GetChildAt(0);
		Test.Assert(child.Layout.FlexGrow.Value == 0, "and nothing was written");
	}

	// ---- The common vocabulary ----------------------------------------------------------------

	[Test]
	public static void TheIdentityAttributesNameAndClassAView()
	{
		let view = Load("<Label id=\"title\" class=\"heading bold\"/>");
		defer view.ReleaseRef();

		Test.Assert(view.Name == "title");
		Test.Assert(view.HasClass("heading"));
		Test.Assert(view.HasClass("bold"), "space separated, as in HTML");
	}

	[Test]
	public static void TheCommonViewAttributesApply()
	{
		let view = Load("""
			<Panel visibility="hidden" is-enabled="false" opacity="0.5" padding="4 8"
			       cursor="hand" tooltip="Help" is-focusable="true" is-tab-stop="true"
			       tab-index="3" clips-content="true"/>
			""");
		defer view.ReleaseRef();

		Test.Assert(view.Visibility == .Hidden);
		Test.Assert(!view.IsEnabled);
		Test.Assert(view.Opacity == 0.5f);
		Test.Assert(view.Cursor == .Hand);
		Test.Assert(view.TooltipText == "Help");
		Test.Assert(view.IsFocusable);
		Test.Assert(view.IsTabStop);
		Test.Assert(view.TabIndex == 3);
		Test.Assert(view.ClipsContent);
		Test.Assert((view as ViewGroup).Padding == Thickness(8, 4, 8, 4));
	}

	/// Markup's boolean is the literal `true` and nothing else, so a typo reads false rather
	/// than as something unintended.
	[Test]
	public static void OnlyTheLiteralTrueIsTrue()
	{
		let yes = Load("<Panel is-focusable=\"true\"/>");
		defer yes.ReleaseRef();
		Test.Assert(yes.IsFocusable);

		let no = Load("<Panel is-focusable=\"True\"/>");
		defer no.ReleaseRef();
		Test.Assert(!no.IsFocusable, "not the capitalised spelling");

		let nonsense = Load("<Panel is-focusable=\"yes\"/>");
		defer nonsense.ReleaseRef();
		Test.Assert(!nonsense.IsFocusable);
	}

	// ---- Layout -------------------------------------------------------------------------------

	[Test]
	public static void SizesAndMarginsWriteTheLayout()
	{
		let sized = Load("<Label width=\"100\" height=\"40\" margin=\"5\"/>");
		defer sized.ReleaseRef();
		Test.Assert(sized.Layout.Width.Value.kind == .Fixed);
		Test.Assert(sized.Layout.Margin.Value.Left == 5);

		let relative = Load("<Label width=\"match\" height=\"wrap\"/>");
		defer relative.ReleaseRef();
		Test.Assert(relative.Layout.Width.Value.kind == .Match);
		Test.Assert(relative.Layout.Height.Value.kind == .Wrap);
	}

	/// The layout vocabulary is the SAME on every element, whatever its parent: a frame's
	/// child may carry flex-grow and dock, and they simply wait for a parent that reads them.
	[Test]
	public static void TheLayoutVocabularyAppliesRegardlessOfParent()
	{
		let root = Load("""
			<Frame width="300" margin="4">
				<Label text="X" flex-grow="1" dock="right" gravity="Bottom"/>
			</Frame>
			""");
		defer root.ReleaseRef();

		Test.Assert(root.Layout.Width.Value.kind == .Fixed);
		Test.Assert(root.Layout.Margin.Value.Left == 4);

		let child = (root as FrameLayout).GetChildAt(0);
		Test.Assert(child.Layout.FlexGrow.Value == 1);
		Test.Assert(child.Layout.Dock == Dock.Right);
		Test.Assert(child.Layout.Gravity == Gravity.Bottom);
	}

	[Test]
	public static void GridAndAbsolutePlacementWriteTheLayout()
	{
		let root = Load("""
			<Grid>
				<Label grid-row="1" grid-column="2" grid-row-span="2" grid-column-span="3"/>
				<Label position="absolute" left="7" top="9" right="11" bottom="13" z-index="4"/>
			</Grid>
			""");
		defer root.ReleaseRef();

		let group = root as GridLayout;
		let placed = group.GetChildAt(0).Layout;
		Test.Assert(placed.GridRow == 1);
		Test.Assert(placed.GridColumn == 2);
		Test.Assert(placed.GridRowSpan == 2);
		Test.Assert(placed.GridColumnSpan == 3);

		let absolute = group.GetChildAt(1).Layout;
		Test.Assert(absolute.Position.Value == .Absolute);
		Test.Assert(absolute.Left.Value == 7);
		Test.Assert(absolute.Top.Value == 9);
		Test.Assert(absolute.Right.Value == 11);
		Test.Assert(absolute.Bottom.Value == 13);
		Test.Assert(absolute.ZIndex.Value == 4);
	}

	/// Gravity is a SET, so it combines with a bar.
	[Test]
	public static void GravityCombinesWithABar()
	{
		Test.Assert(MarkupRegistry.ParseGravity("Center") == .Center);
		Test.Assert(MarkupRegistry.ParseGravity("Bottom|Right") == (Gravity.Bottom | Gravity.Right));
		Test.Assert(MarkupRegistry.ParseGravity("TopLeft") == .TopLeft);
		Test.Assert(MarkupRegistry.ParseGravity("nonsense") == .None);
	}

	/// Length units reach the layout intact: dp, per cent, em and a calc all survive as what
	/// they are, rather than being flattened to a number at parse time.
	[Test]
	public static void TheLengthUnitsSurviveIntoTheLayout()
	{
		var layout = LayoutStyle();

		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "position", "absolute"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "right", "12"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "bottom", "7.5"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "z-index", "-2"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "min-width", "40"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "max-width", "50%"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "min-height", "2em"));
		Test.Assert(MarkupRegistry.ApplyLayoutAttribute(ref layout, "max-height", "calc(100% - 20)"));

		Test.Assert(layout.Position.Value == .Absolute);
		Test.Assert(layout.Position.IsDeclared);
		Test.Assert(layout.Right.Value == 12);
		Test.Assert(layout.Bottom.Value == 7.5f);
		Test.Assert(layout.ZIndex.Value == -2);
		Test.Assert(layout.MinWidth.Value.dp == 40);
		Test.Assert(layout.MaxWidth.Value.percent == 50);
		Test.Assert(layout.MinHeight.Value.em == 2);
		// A calc keeps BOTH components, which is what makes it a calc.
		Test.Assert(layout.MaxHeight.Value.percent == 100);
		Test.Assert(layout.MaxHeight.Value.dp == -20);

		// What was never written stays undeclared, so the cascade can still fill it.
		Test.Assert(!layout.Left.IsDeclared);
	}

	/// A percentage and an em in markup measure against the CONTAINING box and the font size,
	/// the same as they would from a sheet.
	[Test]
	public static void RelativeSizesInMarkupMeasureAgainstTheirContext()
	{
		EnsureInit();

		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		context.SetStyleSheet(loader.Load("View { font-size: 20; }"));

		let frame = MarkupLoader.LoadFromString("""
			<Frame width="match" height="match">
				<Label width="50%" height="2em"/>
				<Label width="calc(100% - 40)"/>
			</Frame>
			""");
		root.AddView(frame);
		UITest.LayoutPass(context, root);

		let group = frame as FrameLayout;
		let half = group.GetChildAt(0);
		Test.Assert(half.Width == 200, "half of the 400 containing box");
		Test.Assert(half.Height == 40, "two of the 20 font size");

		Test.Assert(group.GetChildAt(1).Width == 360, "the whole box less 40");
	}

	/// The completion vocabulary and the loader read the SAME table, so they cannot drift.
	[Test]
	public static void EveryLayoutAttributeIsInTheCompletionVocabulary()
	{
		EnsureInit();

		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		MarkupRegistry.CollectAttributeNames("Label", names);

		for (let expected in MarkupRegistry.LayoutAttributeNames)
		{
			var found = false;
			for (let name in names)
				found = found || (name == expected);

			Test.Assert(found, "a layout attribute is missing from the vocabulary");
		}

		// And the element's own properties are there too.
		var sawText = false;
		for (let name in names)
			sawText = sawText || (name == "text");

		Test.Assert(sawText);
	}

	// ---- Control properties -------------------------------------------------------------------

	[Test]
	public static void ControlPropertiesReachTheirControls()
	{
		let checkBox = Load("<CheckBox text=\"Accept\" is-checked=\"true\"/>");
		defer checkBox.ReleaseRef();
		Test.Assert((checkBox as CheckBox).Text.Value == "Accept");
		Test.Assert((checkBox as CheckBox).IsChecked.Value);

		let slider = Load("<Slider min=\"10\" max=\"90\" value=\"50\" step=\"5\"/>");
		defer slider.ReleaseRef();
		let s = slider as Slider;
		Test.Assert(s.Min.Value == 10);
		Test.Assert(s.Max.Value == 90);
		Test.Assert(s.Value.Value == 50);
		Test.Assert(s.Step.Value == 5);

		let edit = Load("<EditText text=\"Hi\" placeholder=\"Type\" is-read-only=\"true\" multiline=\"true\" max-length=\"20\"/>");
		defer edit.ReleaseRef();
		let e = edit as EditText;
		Test.Assert(e.Text == "Hi");
		Test.Assert(e.Placeholder.Value == "Type");
		Test.Assert(e.IsReadOnly.Value);
		Test.Assert(e.Multiline.Value);
		Test.Assert(e.MaxLength.Value == 20);

		let progress = Load("<ProgressBar value=\"0.25\"/>");
		defer progress.ReleaseRef();
		Test.Assert((progress as ProgressBar).Value.Value == 0.25f);
	}

	[Test]
	public static void TheFontPropertiesReachLabelAndButton()
	{
		let label = Load("<Label text=\"A\" font-size=\"22\" font-family=\"Serif\"/>");
		defer label.ReleaseRef();
		Test.Assert((label as Label).FontSize.Value.Value == 22);
		Test.Assert((label as Label).FontFamily.Value == "Serif");

		let button = Load("<Button text=\"B\" font-family=\"Mono\"/>");
		defer button.ReleaseRef();
		Test.Assert((button as Button).FontFamily.Value == "Mono");
	}

	/// Flex reads the whole CSS wrap vocabulary, gaps included.
	[Test]
	public static void FlexReadsItsWrapAndGapVocabulary()
	{
		let root = Load("<Flex wrap=\"wrap\" align-content=\"center\" gap=\"8 4\"><Panel flex-basis=\"40\"/></Flex>");
		defer root.ReleaseRef();

		let flex = root as FlexLayout;
		Test.Assert(flex.Wrap);
		Test.Assert(flex.AlignContent == .Center);
		Test.Assert(flex.RowGap.Value == 8);
		Test.Assert(flex.ColumnGap.Value == 4);
		// Row and column are AXES: a horizontal flex takes the column gap along its main axis.
		Test.Assert(flex.MainGap == 4);
		Test.Assert(flex.CrossGap == 8);
		Test.Assert(flex.GetChildAt(0).Layout.FlexBasis.Value.dp == 40);

		// One value means both; a named gap then overrides its own axis.
		let single = Load("<Flex gap=\"6\" row-gap=\"2\"/>");
		defer single.ReleaseRef();
		Test.Assert((single as FlexLayout).RowGap.Value == 2);
		Test.Assert((single as FlexLayout).ColumnGap.Value == 6);
	}

	// ---- Inline style -------------------------------------------------------------------------

	[Test]
	public static void TheStyleAttributeAppliesInlineDeclarations()
	{
		let one = Load("<Label style=\"font-size: 20;\"/>");
		defer one.ReleaseRef();
		Test.Assert(one.ResolveStyleFloat(.FontSize, 0) == 20);

		let several = Load("<Panel style=\"font-size: 18; corner-radius: 5;\"/>");
		defer several.ReleaseRef();
		Test.Assert(several.ResolveStyleFloat(.FontSize, 0) == 18);
		Test.Assert(several.ResolveStyleFloat(.CornerRadius, 0) == 5);
	}

	/// An inline style BEATS a rule from the context's sheet, which is what inline means.
	[Test]
	public static void AnInlineStyleBeatsTheContextSheet()
	{
		EnsureInit();

		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		context.SetStyleSheet(loader.Load("Label { font-size: 11; }"));

		let plain = MarkupLoader.LoadFromString("<Label text=\"A\"/>");
		root.AddView(plain);
		Test.Assert(plain.ResolveStyleFloat(.FontSize, 0) == 11, "from the sheet");

		let styled = MarkupLoader.LoadFromString("<Label text=\"B\" style=\"font-size: 33;\"/>");
		root.AddView(styled);
		Test.Assert(styled.ResolveStyleFloat(.FontSize, 0) == 33, "inline wins");
	}

	/// A class in markup resolves against the sheet, which is how a document picks a theme's
	/// look without naming any value itself.
	[Test]
	public static void AClassInMarkupResolvesAgainstTheSheet()
	{
		EnsureInit();

		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root, 400, 300);
		defer { root.ReleaseRef(); delete context; }

		let loader = scope StyleSheetLoader();
		context.SetStyleSheet(loader.Load(".danger { font-size: 27; }"));

		let view = MarkupLoader.LoadFromString("<Label class=\"danger\" text=\"A\"/>");
		root.AddView(view);

		Test.Assert(view.ResolveStyleFloat(.FontSize, 0) == 27);
	}
}
