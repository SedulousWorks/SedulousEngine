namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class MarkupLoaderTests
{
	static this()
	{
		MarkupLoader.Initialize();
		StyleSheetLoader.InitializeGlobals();
	}

	// === Basic element creation ===

	[Test]
	public static void CreatesLabel()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="Hello"/>
			""");

		Test.Assert(view != null);
		Test.Assert(view is Label);
		let label = view as Label;
		Test.Assert(label.Text.Value != null);
		Test.Assert(StringView(label.Text.Value) == "Hello");

		delete view;
	}

	[Test]
	public static void CreatesButton()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Button text="Click Me"/>
			""");

		Test.Assert(view != null);
		Test.Assert(view is Button);
		let btn = view as Button;
		Test.Assert(StringView(btn.Text.Value) == "Click Me");

		delete view;
	}

	[Test]
	public static void TextContent_SetsText()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Button>Click Me</Button>
			""");

		Test.Assert(view != null);
		let btn = view as Button;
		Test.Assert(btn != null);
		Test.Assert(StringView(btn.Text.Value) == "Click Me");

		delete view;
	}

	// === Hierarchy ===

	[Test]
	public static void FlexWithChildren()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical" spacing="8">
			  <Label text="First"/>
			  <Label text="Second"/>
			</Flex>
			""");

		Test.Assert(view != null);
		Test.Assert(view is FlexLayout);
		let flex = view as FlexLayout;
		Test.Assert(flex.Direction == .Vertical);
		Test.Assert(flex.Spacing == 8);
		Test.Assert(flex.ChildCount == 2);

		let first = flex.GetChildAt(0) as Label;
		Test.Assert(first != null);
		Test.Assert(StringView(first.Text.Value) == "First");

		let second = flex.GetChildAt(1) as Label;
		Test.Assert(second != null);
		Test.Assert(StringView(second.Text.Value) == "Second");

		delete view;
	}

	[Test]
	public static void NestedHierarchy()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical">
			  <Flex direction="horizontal" spacing="4">
			    <Button text="A"/>
			    <Button text="B"/>
			  </Flex>
			  <Label text="Footer"/>
			</Flex>
			""");

		Test.Assert(view != null);
		let outer = view as FlexLayout;
		Test.Assert(outer != null);
		Test.Assert(outer.ChildCount == 2);

		let inner = outer.GetChildAt(0) as FlexLayout;
		Test.Assert(inner != null);
		Test.Assert(inner.Direction == .Horizontal);
		Test.Assert(inner.ChildCount == 2);

		delete view;
	}

	// === Special attributes ===

	[Test]
	public static void IdAttribute_RegistersName()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical">
			  <Button id="my-btn" text="OK"/>
			  <Label id="my-label" text="Status"/>
			</Flex>
			""", ctx);

		root.AddView(view);

		let btn = root.FindByName<Button>("my-btn");
		Test.Assert(btn != null);
		Test.Assert(StringView(btn.Text.Value) == "OK");

		let label = root.FindByName<Label>("my-label");
		Test.Assert(label != null);
		Test.Assert(StringView(label.Text.Value) == "Status");
	}

	[Test]
	public static void ClassAttribute()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label class="primary large" text="Styled"/>
			""");

		Test.Assert(view != null);
		let label = view as Label;
		Test.Assert(label.HasClass("primary"));
		Test.Assert(label.HasClass("large"));

		delete view;
	}

	[Test]
	public static void VisibilityAttribute()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label visibility="gone" text="Hidden"/>
			""");

		Test.Assert(view != null);
		Test.Assert(view.Visibility == .Gone);

		delete view;
	}

	[Test]
	public static void IsEnabledAttribute()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Button is-enabled="false" text="Disabled"/>
			""");

		Test.Assert(view != null);
		Test.Assert(view.IsEnabled == false);

		delete view;
	}

	[Test]
	public static void OpacityAttribute()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label opacity="0.5" text="Faded"/>
			""");

		Test.Assert(view != null);
		Test.Assert(Math.Abs(view.Opacity - 0.5f) < 0.01f);

		delete view;
	}

	[Test]
	public static void PaddingAttribute()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex padding="8 12">
			  <Label text="Padded"/>
			</Flex>
			""");

		Test.Assert(view != null);
		let flex = view as FlexLayout;
		Test.Assert(flex.Padding.Top == 8);
		Test.Assert(flex.Padding.Left == 12);

		delete view;
	}

	// === Layout params ===

	[Test]
	public static void WidthHeight_LayoutParams()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="horizontal">
			  <Label text="Fixed" width="200" height="40"/>
			</Flex>
			""");

		let flex = view as FlexLayout;
		Test.Assert(flex != null);
		let child = flex.GetChildAt(0);
		Test.Assert(child.LayoutParams != null);
		Test.Assert(child.LayoutParams.Width case .Fixed);
		Test.Assert(child.LayoutParams.Height case .Fixed);

		delete view;
	}

	[Test]
	public static void MatchWrap_LayoutParams()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex>
			  <Label text="Match" width="match" height="wrap"/>
			</Flex>
			""");

		let flex = view as FlexLayout;
		let child = flex.GetChildAt(0);
		Test.Assert(child.LayoutParams.Width case .Match);
		Test.Assert(child.LayoutParams.Height case .Wrap);

		delete view;
	}

	[Test]
	public static void FlexGrow_LayoutParam()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="horizontal">
			  <Button text="A" grow="1"/>
			  <Button text="B" grow="2"/>
			</Flex>
			""");

		let flex = view as FlexLayout;
		let a = flex.GetChildAt(0);
		let b = flex.GetChildAt(1);
		let alpA = a.LayoutParams as FlexLayout.LayoutParams;
		let alpB = b.LayoutParams as FlexLayout.LayoutParams;
		Test.Assert(alpA != null && alpA.Grow == 1);
		Test.Assert(alpB != null && alpB.Grow == 2);

		delete view;
	}

	[Test]
	public static void FrameGravity_LayoutParam()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Frame>
			  <Label text="Centered" gravity="Center"/>
			</Frame>
			""");

		let frame = view as FrameLayout;
		let child = frame.GetChildAt(0);
		let flp = child.LayoutParams as FrameLayout.LayoutParams;
		Test.Assert(flp != null && flp.Gravity == .Center);

		delete view;
	}

	[Test]
	public static void DockLayout_Param()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Dock>
			  <Label text="Top" dock="top"/>
			  <Label text="Fill" dock="fill"/>
			</Dock>
			""");

		let dock = view as DockLayout;
		Test.Assert(dock.ChildCount == 2);
		let topChild = dock.GetChildAt(0);
		let dlp = topChild.LayoutParams as DockLayout.LayoutParams;
		Test.Assert(dlp != null && dlp.Dock == .Top);

		delete view;
	}

	// === Control properties ===

	[Test]
	public static void CheckBox_Properties()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<CheckBox text="Accept" is-checked="true"/>
			""");

		let cb = view as CheckBox;
		Test.Assert(cb != null);
		Test.Assert(StringView(cb.Text.Value) == "Accept");
		Test.Assert(cb.IsChecked.Value == true);

		delete view;
	}

	[Test]
	public static void Slider_Properties()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Slider min="0" max="100" value="50" step="5"/>
			""");

		let slider = view as Slider;
		Test.Assert(slider != null);
		Test.Assert(slider.Min.Value == 0);
		Test.Assert(slider.Max.Value == 100);
		Test.Assert(slider.Value.Value == 50);
		Test.Assert(slider.Step.Value == 5);

		delete view;
	}

	[Test]
	public static void EditText_Properties()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<EditText text="hello" placeholder="Type here" is-read-only="false" max-length="100"/>
			""");

		let edit = view as EditText;
		Test.Assert(edit != null);
		Test.Assert(StringView(edit.Text) == "hello");
		Test.Assert(edit.MaxLength.Value == 100);

		delete view;
	}

	[Test]
	public static void ProgressBar_Properties()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<ProgressBar value="0.75"/>
			""");

		let pb = view as ProgressBar;
		Test.Assert(pb != null);
		Test.Assert(Math.Abs(pb.Value.Value - 0.75f) < 0.01f);

		delete view;
	}

	[Test]
	public static void Label_FontSize()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="Big" font-size="24"/>
			""");

		let label = view as Label;
		Test.Assert(label != null);
		Test.Assert(label.FontSize.Value.HasValue);
		Test.Assert(label.FontSize.Value.Value == 24);

		delete view;
	}

	[Test]
	public static void Label_FontFamily()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="Decorative" font-family="JungleAdventurer"/>
			""");

		let label = view as Label;
		Test.Assert(label != null);
		Test.Assert(label.FontFamily.Value != null);
		Test.Assert(StringView(label.FontFamily.Value) == "JungleAdventurer");

		delete view;
	}

	[Test]
	public static void Button_FontFamily()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Button text="Go" font-family="AttackOfMonster"/>
			""");

		let btn = view as Button;
		Test.Assert(btn != null);
		Test.Assert(btn.FontFamily.Value != null);
		Test.Assert(StringView(btn.FontFamily.Value) == "AttackOfMonster");

		delete view;
	}

	// === style="..." inline-style attribute ===

	[Test]
	public static void Style_SinglePrimitive()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="hi" style="font-size: 22;"/>
			""");

		let label = view as Label;
		Test.Assert(label.GetInlineStyle(.FontSize).AsFloat == 22f);

		delete view;
	}

	[Test]
	public static void Style_MultipleDeclarations()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="hi" style="font-size: 18; text-color: #ff0000; padding: 4 8;"/>
			""");

		let label = view as Label;
		Test.Assert(label.GetInlineStyle(.FontSize).AsFloat == 18f);
		let c = label.GetInlineStyle(.TextColor).AsColor;
		Test.Assert(c.HasValue && c.Value.R == 255 && c.Value.G == 0);
		let pad = label.GetInlineStyle(.Padding).AsThickness;
		Test.Assert(pad.HasValue && pad.Value.Top == 4 && pad.Value.Left == 8);

		delete view;
	}

	[Test]
	public static void Style_StringProperty()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="hi" style="font-family: JungleAdventurer;"/>
			""");

		let label = view as Label;
		Test.Assert(label.GetInlineStyle(.FontFamily).AsString.Value == "JungleAdventurer");

		delete view;
	}

	[Test]
	public static void Style_BeatsContextSheetRule()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = new StyleSheet();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();
		sheet.ForType(typeof(Label)).Set(.TextColor, Color32(0, 0, 255, 255));

		let view = MarkupLoader.LoadFromString(
			"""
			<Label text="hi" style="text-color: #00ff00;"/>
			""", ctx);
		root.AddView(view);

		let label = view as Label;
		// Inline (green) wins over context-sheet (blue).
		let c = label.ResolveStyleColor(.TextColor);
		Test.Assert(c.G == 255 && c.B == 0);
	}

	[Test]
	public static void Style_DrawableValue_OwnedByView()
	{
		// rgb() produces a ColorDrawable via the SSS factory; the
		// drawable is owned by the view's inline sheet so deleting
		// the view doesn't leak.
		let view = MarkupLoader.LoadFromString(
			"""
			<Panel style="background: rgb(40, 120, 60);"/>
			""");

		let panel = view as Panel;
		Test.Assert(panel.GetInlineStyle(.Background).AsDrawable != null);
		Test.Assert(panel.GetInlineStyle(.Background).AsDrawable is ColorDrawable);

		delete view;
	}

	[Test]
	public static void Style_OnVariousTags()
	{
		// "style" is a generic attribute - works on every view, not
		// only the tags with per-attribute registrations.
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex>
			  <Button text="A" style="font-size: 14;"/>
			  <CheckBox text="B" style="font-size: 16;"/>
			</Flex>
			""");

		let flex = view as FlexLayout;
		let btn = flex.GetChildAt(0) as Button;
		let cb = flex.GetChildAt(1) as CheckBox;
		Test.Assert(btn.GetInlineStyle(.FontSize).AsFloat == 14f);
		Test.Assert(cb.GetInlineStyle(.FontSize).AsFloat == 16f);

		delete view;
	}

	// === Aliases ===

	[Test]
	public static void FlexLayout_Alias()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<FlexLayout direction="horizontal">
			  <Label text="A"/>
			</FlexLayout>
			""");

		Test.Assert(view is FlexLayout);
		let flex = view as FlexLayout;
		Test.Assert(flex.Direction == .Horizontal);

		delete view;
	}

	// === Unknown elements ===

	[Test]
	public static void UnknownElement_ReturnsNull()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<NonExistentWidget/>
			""");

		Test.Assert(view == null);
	}

	// === Invalid XML ===

	[Test]
	public static void InvalidXml_ReturnsNull()
	{
		let view = MarkupLoader.LoadFromString("<not valid xml");
		Test.Assert(view == null);
	}

	// === Empty ===

	[Test]
	public static void EmptyContainer()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical"/>
			""");

		Test.Assert(view != null);
		let flex = view as FlexLayout;
		Test.Assert(flex.ChildCount == 0);

		delete view;
	}

	// === Margin on layout params ===

	[Test]
	public static void Margin_LayoutParam()
	{
		let view = MarkupLoader.LoadFromString(
			"""
			<Flex>
			  <Label text="Margined" margin="4 8"/>
			</Flex>
			""");

		let flex = view as FlexLayout;
		let child = flex.GetChildAt(0);
		Test.Assert(child.LayoutParams.Margin.Top == 4);
		Test.Assert(child.LayoutParams.Margin.Left == 8);

		delete view;
	}

	// === Style resolution with markup ===

	[Test]
	public static void StyleClass_ResolvesTheme()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = DarkTheme.Create();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = MarkupLoader.LoadFromString(
			"""
			<Flex direction="vertical">
			  <Button id="btn" text="Themed"/>
			</Flex>
			""", ctx);

		root.AddView(view);

		let btn = root.FindByName<Button>("btn");
		Test.Assert(btn != null);
		// Button should resolve background from theme (ButtonBase type selector)
		let bg = btn.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);
	}
}
