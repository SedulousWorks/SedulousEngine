namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.UI.Resources;
using Sedulous.Core.Mathematics;

class ThemeXmlParserTests
{
	[Test]
	public static void Parse_BasicTheme()
	{
		let xml = """
			<Theme name="TestTheme">
			  <Color key="Button.Background" value="60,120,200,255"/>
			  <Dimension key="Button.CornerRadius" value="8"/>
			  <Padding key="Button.Padding" value="10,6"/>
			  <FontSize key="Label.FontSize" value="18"/>
			  <String key="App.Title" value="Test App"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		Test.Assert(theme.Name == "TestTheme");

		let bgColor = theme.GetColor("Button.Background");
		Test.Assert(bgColor.R == 60 && bgColor.G == 120 && bgColor.B == 200);

		Test.Assert(theme.GetDimension("Button.CornerRadius") == 8);

		let padding = theme.GetPadding("Button.Padding");
		Test.Assert(padding.Left == 10 && padding.Top == 6);

		Test.Assert(theme.GetFontSize("Label.FontSize") == 18);

		let title = theme.GetString("App.Title");
		Test.Assert(title != null && title == "Test App");
	}

	[Test]
	public static void Parse_WithPalette()
	{
		let xml = """
			<Theme name="Custom">
			  <Palette primary="100,150,200" background="20,20,25" text="230,230,240"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		Test.Assert(theme.Palette.Primary.R == 100);
		Test.Assert(theme.Palette.Background.R == 20);
		Test.Assert(theme.Palette.Text.R == 230);
	}

	[Test]
	public static void Parse_InvalidXml_ReturnsNull()
	{
		let theme = ThemeXmlParser.Parse("<not valid xml");
		Test.Assert(theme == null);
	}

	[Test]
	public static void Parse_WrongRoot_ReturnsNull()
	{
		let theme = ThemeXmlParser.Parse("<NotATheme/>");
		Test.Assert(theme == null);
	}

	[Test]
	public static void Parse_Padding_UniformAndFull()
	{
		let xml = """
			<Theme name="PadTest">
			  <Padding key="Uniform" value="10"/>
			  <Padding key="TwoAxis" value="8,4"/>
			  <Padding key="Full" value="1,2,3,4"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		let uniform = theme.GetPadding("Uniform");
		Test.Assert(uniform.Left == 10 && uniform.Top == 10 && uniform.Right == 10);

		let twoAxis = theme.GetPadding("TwoAxis");
		Test.Assert(twoAxis.Left == 8 && twoAxis.Top == 4);

		let full = theme.GetPadding("Full");
		Test.Assert(full.Left == 1 && full.Top == 2 && full.Right == 3 && full.Bottom == 4);
	}

	[Test]
	public static void UILayoutResource_LoadView()
	{
		UIRegistry.RegisterBuiltins();

		let resource = new UILayoutResource();
		resource.XmlSource = new String("""
			<Label text="From Resource"/>
			""");
		resource.AddRef();

		let view = resource.LoadView();
		Test.Assert(view != null);
		Test.Assert(view is Label);
		Test.Assert((view as Label).Text == "From Resource");

		delete view;
		//resource.ReleaseRefNoDelete();
		//delete resource;
		resource.ReleaseRef();
	}
}
