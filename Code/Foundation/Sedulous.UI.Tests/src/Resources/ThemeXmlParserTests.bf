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

	// ==========================================================
	// Drawable parsing
	// ==========================================================

	[Test]
	public static void Parse_Drawable_Color()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Test.Bg" type="Color" color="255,0,0,255"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Test.Bg");
		Test.Assert(drawable != null);
		Test.Assert(drawable is ColorDrawable);
		Test.Assert((drawable as ColorDrawable).Color.R == 255);
	}

	[Test]
	public static void Parse_Drawable_RoundedRect()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Panel.Bg" type="RoundedRect" fill="40,40,50,255" radius="6" border="80,80,100,255" borderWidth="1"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Panel.Bg");
		Test.Assert(drawable != null);
		Test.Assert(drawable is RoundedRectDrawable);

		let rrd = drawable as RoundedRectDrawable;
		Test.Assert(rrd.FillColor.R == 40);
		Test.Assert(rrd.CornerRadius == 6);
		Test.Assert(rrd.BorderWidth == 1);
		Test.Assert(rrd.BorderColor.R == 80);
	}

	[Test]
	public static void Parse_Drawable_SVG_CDATA()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Icon.Check" type="SVG"><![CDATA[<svg viewBox="0 0 16 16"><circle cx="8" cy="8" r="6" fill="red"/></svg>]]></Drawable>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Icon.Check");
		Test.Assert(drawable != null);
		Test.Assert(drawable is SVGDrawable);

		let svgD = drawable as SVGDrawable;
		let size = svgD.IntrinsicSize;
		Test.Assert(size.HasValue);
		Test.Assert(size.Value.X == 16);
	}

	[Test]
	public static void Parse_Drawable_StateList()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Button.Background" type="StateList">
			    <State state="Normal" type="Color" color="60,60,80,255"/>
			    <State state="Hover" type="Color" color="80,80,100,255"/>
			    <State state="Pressed" type="Color" color="40,40,60,255"/>
			    <State state="Disabled" type="Color" color="30,30,40,128"/>
			  </Drawable>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Button.Background");
		Test.Assert(drawable != null);
		Test.Assert(drawable is StateListDrawable);

		let sl = drawable as StateListDrawable;
		Test.Assert(sl.Get(.Normal) != null);
		Test.Assert(sl.Get(.Hover) != null);
		Test.Assert(sl.Get(.Pressed) != null);
		Test.Assert(sl.Get(.Disabled) != null);

		// Verify correct colors.
		Test.Assert((sl.Get(.Normal) as ColorDrawable).Color.R == 60);
		Test.Assert((sl.Get(.Hover) as ColorDrawable).Color.R == 80);
		Test.Assert((sl.Get(.Pressed) as ColorDrawable).Color.R == 40);
	}

	[Test]
	public static void Parse_Drawable_Image_WithLoader()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Button.Background" type="Image" src="button.png"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml, scope (path) =>
		{
			if (path == "button.png")
			{
				let data = new uint8[16 * 16 * 4];
				return new Sedulous.Images.OwnedImageData(16, 16, .RGBA8, data);
			}
			return null;
		});
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Button.Background");
		Test.Assert(drawable != null);
		Test.Assert(drawable is ImageDrawable);
	}

	[Test]
	public static void Parse_Drawable_NineSlice_WithLoader()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Panel.Bg" type="NineSlice" src="panel.png" slices="8,8,8,8"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml, scope (path) =>
		{
			if (path == "panel.png")
			{
				let data = new uint8[32 * 32 * 4];
				return new Sedulous.Images.OwnedImageData(32, 32, .RGBA8, data);
			}
			return null;
		});
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Panel.Bg");
		Test.Assert(drawable != null);
		Test.Assert(drawable is NineSliceDrawable);

		let nsd = drawable as NineSliceDrawable;
		Test.Assert(nsd.Slices.Left == 8);
		Test.Assert(nsd.Slices.Top == 8);
	}

	[Test]
	public static void Parse_Drawable_Image_NoLoader_Skipped()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Button.Background" type="Image" src="button.png"/>
			</Theme>
			""";

		// No image loader provided - drawable should not be created.
		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		Test.Assert(theme.GetDrawable("Button.Background") == null);
	}

	[Test]
	public static void Parse_Drawable_Unknown_ReturnsNull()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Test" type="UnknownType"/>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml);
		Test.Assert(theme != null);
		defer delete theme;

		Test.Assert(theme.GetDrawable("Test") == null);
	}

	[Test]
	public static void Parse_Drawable_StateList_WithImages()
	{
		let xml = """
			<Theme name="DrawTest">
			  <Drawable key="Button.Background" type="StateList">
			    <State state="Normal" type="NineSlice" src="btn_normal.png" slices="4,4,4,4"/>
			    <State state="Hover" type="NineSlice" src="btn_hover.png" slices="4,4,4,4"/>
			  </Drawable>
			</Theme>
			""";

		let theme = ThemeXmlParser.Parse(xml, scope (path) =>
		{
			let data = new uint8[16 * 16 * 4];
			return new Sedulous.Images.OwnedImageData(16, 16, .RGBA8, data);
		});
		Test.Assert(theme != null);
		defer delete theme;

		let drawable = theme.GetDrawable("Button.Background");
		Test.Assert(drawable != null);
		Test.Assert(drawable is StateListDrawable);

		let sl = drawable as StateListDrawable;
		Test.Assert(sl.Get(.Normal) is NineSliceDrawable);
		Test.Assert(sl.Get(.Hover) is NineSliceDrawable);
	}

	// ==========================================================
	// Original tests continue
	// ==========================================================

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
