namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;

class XmlLoaderTests
{
	static this()
	{
		UIRegistry.RegisterBuiltins();
	}

	[Test]
	public static void LoadSimpleLabel()
	{
		let xml = """
			<Label text="Hello World"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view is Label);

		let label = view as Label;
		Test.Assert(label.Text != null && label.Text == "Hello World");

		delete view;
	}

	[Test]
	public static void LoadLinearLayoutWithChildren()
	{
		let xml = """
			<LinearLayout orientation="Vertical" spacing="8" padding="10">
			  <Label text="First"/>
			  <Label text="Second"/>
			</LinearLayout>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view is LinearLayout);

		let layout = view as LinearLayout;
		Test.Assert(layout.Orientation == .Vertical);
		Test.Assert(layout.Spacing == 8);
		Test.Assert(layout.Padding.Left == 10);
		Test.Assert(layout.ChildCount == 2);

		let first = layout.GetChildAt(0) as Label;
		Test.Assert(first != null && first.Text == "First");

		let second = layout.GetChildAt(1) as Label;
		Test.Assert(second != null && second.Text == "Second");

		delete view;
	}

	[Test]
	public static void LayoutParams_FromParentType()
	{
		let xml = """
			<LinearLayout orientation="Horizontal">
			  <Label text="A" layout_weight="2" layout_width="match_parent"/>
			  <Label text="B" layout_weight="1"/>
			</LinearLayout>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let layout = view as LinearLayout;
		Test.Assert(layout != null);

		let a = layout.GetChildAt(0);
		Test.Assert(a.LayoutParams is LinearLayout.LayoutParams);
		let alpA = a.LayoutParams as LinearLayout.LayoutParams;
		Test.Assert(alpA.Weight == 2);
		Test.Assert(alpA.Width == LayoutParams.MatchParent);

		let b = layout.GetChildAt(1);
		let alpB = b.LayoutParams as LinearLayout.LayoutParams;
		Test.Assert(alpB.Weight == 1);

		delete view;
	}

	[Test]
	public static void XName_SetsViewName()
	{
		let xml = """
			<Button text="OK" x:Name="okBtn"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view.Name != null && view.Name == "okBtn");

		delete view;
	}

	[Test]
	public static void Visibility_Parsed()
	{
		let xml = """
			<Label text="Hidden" visibility="Gone"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view.Visibility == .Gone);

		delete view;
	}

	[Test]
	public static void UnknownElement_ReturnsNull()
	{
		let xml = """
			<FooBarWidget text="nope"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view == null);
	}

	[Test]
	public static void FrameLayout_GravityParsed()
	{
		let xml = """
			<FrameLayout>
			  <ColorView layout_gravity="Center"/>
			</FrameLayout>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let frame = view as FrameLayout;
		Test.Assert(frame != null);
		Test.Assert(frame.ChildCount == 1);

		let childLp = frame.GetChildAt(0).LayoutParams as FrameLayout.LayoutParams;
		Test.Assert(childLp != null);
		Test.Assert(childLp.Gravity == .Center);

		delete view;
	}

	[Test]
	public static void NestedLayouts()
	{
		let xml = """
			<LinearLayout orientation="Vertical">
			  <LinearLayout orientation="Horizontal">
			    <Label text="Nested"/>
			  </LinearLayout>
			</LinearLayout>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let outer = view as LinearLayout;
		Test.Assert(outer != null && outer.ChildCount == 1);

		let inner = outer.GetChildAt(0) as LinearLayout;
		Test.Assert(inner != null && inner.Orientation == .Horizontal);
		Test.Assert(inner.ChildCount == 1);

		let label = inner.GetChildAt(0) as Label;
		Test.Assert(label != null && label.Text == "Nested");

		delete view;
	}

	[Test]
	public static void UnknownProperty_StillLoadsView()
	{
		// Unknown property is logged but doesn't prevent the view from loading.
		let xml = """
			<Label text="OK" bogusProperty="whatever"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view is Label);

		let label = view as Label;
		Test.Assert(label.Text == "OK");

		delete view;
	}

	[Test]
	public static void StyleId_Parsed()
	{
		let xml = """
			<Label text="Styled" styleId="Heading"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(view.StyleId != null && view.StyleId == "Heading");

		delete view;
	}

	[Test]
	public static void Enabled_Parsed()
	{
		let xml = """
			<Button text="Disabled" enabled="false"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		Test.Assert(view != null);
		Test.Assert(!view.IsEnabled);

		delete view;
	}

	[Test]
	public static void ParseColor_RGB()
	{
		Test.Assert(UIRegistry.ParseColor("255,0,128", let col));
		Test.Assert(col.R == 255 && col.G == 0 && col.B == 128 && col.A == 255);
	}

	[Test]
	public static void ParseColor_RGBA()
	{
		Test.Assert(UIRegistry.ParseColor("10,20,30,200", let col));
		Test.Assert(col.R == 10 && col.G == 20 && col.B == 30 && col.A == 200);
	}

	[Test]
	public static void ParseColor_Invalid()
	{
		Test.Assert(!UIRegistry.ParseColor("notacolor", let col));
	}

	[Test]
	public static void Label_Properties_FromXml()
	{
		let xml = """
			<Label text="Test" fontSize="24" hAlign="Center" textColor="255,0,0,255"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let label = view as Label;
		Test.Assert(label != null);
		Test.Assert(label.FontSize == 24);
		Test.Assert(label.HAlign == .Center);
		Test.Assert(label.TextColor.R == 255 && label.TextColor.G == 0);

		delete view;
	}

	[Test]
	public static void ColorView_Properties_FromXml()
	{
		let xml = """
			<ColorView color="100,200,50,255" preferredWidth="64" preferredHeight="32"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let cv = view as ColorView;
		Test.Assert(cv != null);
		Test.Assert(cv.Color.R == 100 && cv.Color.G == 200 && cv.Color.B == 50);
		Test.Assert(cv.PreferredWidth == 64);
		Test.Assert(cv.PreferredHeight == 32);

		delete view;
	}

	[Test]
	public static void Spacer_Properties_FromXml()
	{
		let xml = """
			<Spacer spacerWidth="20" spacerHeight="10"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let spacer = view as Spacer;
		Test.Assert(spacer != null);
		Test.Assert(spacer.SpacerWidth == 20);
		Test.Assert(spacer.SpacerHeight == 10);

		delete view;
	}

	[Test]
	public static void FlowLayout_Properties_FromXml()
	{
		let xml = """
			<FlowLayout orientation="Horizontal" hSpacing="8" vSpacing="4"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let flow = view as FlowLayout;
		Test.Assert(flow != null);
		Test.Assert(flow.Orientation == .Horizontal);
		Test.Assert(flow.HSpacing == 8);
		Test.Assert(flow.VSpacing == 4);

		delete view;
	}

	[Test]
	public static void Separator_Properties_FromXml()
	{
		let xml = """
			<Separator orientation="Vertical" separatorThickness="2" color="100,100,100,255"/>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let sep = view as Separator;
		Test.Assert(sep != null);
		Test.Assert(sep.Orientation == .Vertical);
		Test.Assert(sep.SeparatorThickness == 2);
		Test.Assert(sep.Color.R == 100);

		delete view;
	}

	[Test]
	public static void LayoutParams_PixelSize()
	{
		let xml = """
			<LinearLayout orientation="Vertical">
			  <Label text="Fixed" layout_width="200" layout_height="50"/>
			</LinearLayout>
			""";

		let view = UIXmlLoader.LoadFromString(xml);
		let layout = view as LinearLayout;
		let child = layout.GetChildAt(0);
		Test.Assert(child.LayoutParams.Width == 200);
		Test.Assert(child.LayoutParams.Height == 50);

		delete view;
	}
}
