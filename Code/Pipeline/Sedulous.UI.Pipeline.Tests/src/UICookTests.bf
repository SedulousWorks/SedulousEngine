using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.UI;
using Sedulous.UI.Pipeline;
using Sedulous.UI.Resource;

namespace Sedulous.UI.Pipeline.Tests;

/// The cook itself: what reaches the product, and what refuses to cook at all.
class UICookTests
{
	private const String cDocumentType = "Sedulous.UI.Resource.UIDocumentResource";
	private const String cThemeType = "Sedulous.UI.Resource.UIThemeResource";

	[Test]
	public static void ADocumentAndAThemeCookAndLoadBackAsProducts()
	{
		let fixture = scope UIPipelineFixture("roundtrip");
		fixture.StageSource("menu.sml", UIStarterContent.cDocument);
		fixture.StageSource("theme.sss", UIStarterContent.cTheme);

		let documentInstance = fixture.CreateOutput("menu", cDocumentType);
		{
			let asset = scope UIDocumentAsset();
			asset.FileName.Set("menu.sml");
			fixture.Context.Output = documentInstance;
			Test.Assert(scope UIDocumentAssetBuilder().Build(asset, fixture.Context) case .Ok);
		}

		let themeInstance = fixture.CreateOutput("theme", cThemeType);
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set("theme.sss");
			fixture.Context.Output = themeInstance;
			Test.Assert(scope UIThemeAssetBuilder().Build(asset, fixture.Context) case .Ok);
		}

		// Through the resource manager, which is how a game reaches them.
		let documents = scope UIDocumentFactory();
		let themes = scope UIThemeFactory();
		let manager = scope ResourceManager(fixture.Cooked);
		manager.AddFactory(documents);
		manager.AddFactory(themes);

		let document = manager.Bind<UIDocument>(documentInstance.Id);
		Test.Assert(document.Get != null);
		Test.Assert(document.Get.Markup == UIStarterContent.cDocument);

		let theme = manager.Bind<UITheme>(themeInstance.Id);
		Test.Assert(theme.Get != null);
		Test.Assert(!theme.Get.StyleSheet.IsEmpty);

		// And the cooked markup actually builds a tree whose identifiers are addressable, which
		// is what the cook validated on the way through.
		MarkupLoader.Initialize();
		let tree = MarkupLoader.LoadFromString(document.Get.Markup);
		Test.Assert(tree != null);
		let group = tree as ViewGroup;
		Test.Assert(group != null);
		Test.Assert(group.FindByName("ok-btn") != null);
		tree.ReleaseRef();
	}

	[Test]
	public static void MalformedOrUnlinkedPayloadsFailTheCook()
	{
		let fixture = scope UIPipelineFixture("bad");
		fixture.StageSource("bad.sml", "<FlexLayout><Label text=\"unclosed\"</FlexLayout>");
		fixture.StageSource("unknown.sml", "<NotARealControl />");
		fixture.StageSource("empty.sml", "");
		fixture.StageSource("empty.sss", "");
		fixture.Context.Output = fixture.CreateOutput("menu", cDocumentType);

		let documents = scope UIDocumentAssetBuilder();

		let badXml = scope UIDocumentAsset();
		badXml.FileName.Set("bad.sml");
		Test.Assert(documents.Build(badXml, fixture.Context) case .Err, "malformed markup");

		let unknownControl = scope UIDocumentAsset();
		unknownControl.FileName.Set("unknown.sml");
		Test.Assert(documents.Build(unknownControl, fixture.Context) case .Err, "an unknown root");

		let empty = scope UIDocumentAsset();
		empty.FileName.Set("empty.sml");
		Test.Assert(documents.Build(empty, fixture.Context) case .Err, "an empty file");

		// No link at all: there is nothing to cook, which is a failure rather than an empty
		// product that would look fine until something tried to show it.
		let unlinked = scope UIDocumentAsset();
		Test.Assert(documents.Build(unlinked, fixture.Context) case .Err);

		let themes = scope UIThemeAssetBuilder();
		let emptyTheme = scope UIThemeAsset();
		emptyTheme.FileName.Set("empty.sss");
		Test.Assert(themes.Build(emptyTheme, fixture.Context) case .Err);
		let unlinkedTheme = scope UIThemeAsset();
		Test.Assert(themes.Build(unlinkedTheme, fixture.Context) case .Err);
	}

	[Test]
	public static void AGamekitScreenDocumentValidatesAtCook()
	{
		// A screen is GAMEKIT markup rather than a builtin, and the cook registers it so a game's
		// heads up display and menu roots validate. Without that registration this build fails as
		// an unknown control, exactly as the made up one above does.
		let fixture = scope UIPipelineFixture("screen");
		fixture.StageSource("hud.sml",
			"<screen mode=\"overlay\"><Label id=\"hud-timer\" text=\"90\"/></screen>");
		fixture.Context.Output = fixture.CreateOutput("hud", cDocumentType);

		let asset = scope UIDocumentAsset();
		asset.FileName.Set("hud.sml");
		Test.Assert(scope UIDocumentAssetBuilder().Build(asset, fixture.Context) case .Ok);
	}

	[Test]
	public static void ACookOfALinkedSourceReadsTheFileIntoTheProduct()
	{
		let fixture = scope UIPipelineFixture("linked");
		fixture.StageSource("doc.sml", UIStarterContent.cDocument);
		fixture.StageSource("theme.sss", UIStarterContent.cTheme);

		let documentInstance = fixture.CreateOutput("doc", cDocumentType);
		{
			let asset = scope UIDocumentAsset();
			asset.FileName.Set("doc.sml");
			fixture.Context.Output = documentInstance;
			Test.Assert(scope UIDocumentAssetBuilder().Build(asset, fixture.Context) case .Ok);

			let object = documentInstance.ReadObject();
			defer delete object;
			let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as UIDocumentResource;
			Test.Assert(cooked != null);
			Test.Assert(cooked.Markup == UIStarterContent.cDocument);
		}

		let themeInstance = fixture.CreateOutput("theme", cThemeType);
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set("theme.sss");
			fixture.Context.Output = themeInstance;
			Test.Assert(scope UIThemeAssetBuilder().Build(asset, fixture.Context) case .Ok);

			let object = themeInstance.ReadObject();
			defer delete object;
			let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as UIThemeResource;
			Test.Assert(cooked != null);
			Test.Assert(cooked.StyleSheet == UIStarterContent.cTheme);
		}

		// A link whose file is MISSING fails the cook rather than producing an empty product.
		{
			let asset = scope UIDocumentAsset();
			asset.FileName.Set("does-not-exist.sml");
			fixture.Context.Output = documentInstance;
			Test.Assert(scope UIDocumentAssetBuilder().Build(asset, fixture.Context) case .Err);
		}
	}

	// ---- vector images: an SVG asset, and a theme that draws it as an icon ----

	private const String cVectorImageType = "Sedulous.UI.Resource.UIVectorImageResource";
	private const String cHeartSvg = """
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 21 L3 12 A5 5 0 0 1 12 5 A5 5 0 0 1 21 12 Z" fill="#E53935"/></svg>
		""";

	[Test]
	public static void AVectorImageCooksWhenItIsAnSvgTheEngineReadsAndFailsWhenNot()
	{
		let fixture = scope UIPipelineFixture("svg");
		fixture.StageSource("heart.svg", cHeartSvg);
		fixture.StageSource("broken.svg", "<html>not a vector image</html>");

		let builder = scope UIVectorImageAssetBuilder();
		let heart = fixture.CreateOutput("heart", cVectorImageType);
		{
			let asset = scope UIVectorImageAsset();
			asset.FileName.Set("heart.svg");
			fixture.Context.Output = heart;
			Test.Assert(builder.Build(asset, fixture.Context) case .Ok);
		}
		{
			let asset = scope UIVectorImageAsset();
			asset.FileName.Set("broken.svg");
			fixture.Context.Output = fixture.CreateOutput("broken", cVectorImageType);
			Test.Assert(builder.Build(asset, fixture.Context) case .Err);
		}

		let images = scope UIVectorImageFactory();
		let manager = scope ResourceManager(fixture.Cooked);
		manager.AddFactory(images);
		let image = manager.Bind<UIVectorImage>(heart.Id);
		Test.Assert(image.Get != null);
		Test.Assert(image.Get.Svg == cHeartSvg);

		// The importer takes an .svg as a vector image.
		Test.Assert(scope UIFileImporter().Accepts("svg"));
	}

	[Test]
	public static void AThemesIconEmbedsTheVectorImageItNamesAndAnUnknownOneFails()
	{
		let fixture = scope UIPipelineFixture("icon");
		fixture.StageSource("heart.svg", cHeartSvg);

		// The vector image, cooked first (the theme's Reads edge orders it so in a real cook).
		let heart = fixture.CreateOutput("heart", cVectorImageType);
		{
			let asset = scope UIVectorImageAsset();
			asset.FileName.Set("heart.svg");
			fixture.Context.Output = heart;
			Test.Assert(scope UIVectorImageAssetBuilder().Build(asset, fixture.Context) case .Ok);
		}
		let reference = scope String()..Append('{');
		heart.Id.ToString(reference);
		reference.Append('}');
		fixture.StageSource("theme.sss", scope $"@icon heart \"{reference}\";\n.lives-icon {{ background: svg(heart, tint=#E53935); }}\n");

		let asset = scope UIThemeAsset();
		asset.FileName.Set("theme.sss");
		let builder = scope UIThemeAssetBuilder();

		// The scan names the image as content the theme reads, so a changed SVG recooks the theme.
		let dependencies = scope AssetDependencies();
		builder.ScanDependencies(asset, fixture.Context, dependencies);
		Test.Assert((dependencies.Reads.Count == 1) && (dependencies.Reads[0] == heart.Id));

		let themeInstance = fixture.CreateOutput("theme", cThemeType);
		fixture.Context.Output = themeInstance;
		Test.Assert(builder.Build(asset, fixture.Context) case .Ok);
		let themes = scope UIThemeFactory();
		let manager = scope ResourceManager(fixture.Cooked);
		manager.AddFactory(themes);
		let theme = manager.Bind<UITheme>(themeInstance.Id);
		Test.Assert(theme.Get != null);
		Test.Assert(theme.Get.IconIds.Count == 1);
		Test.Assert(theme.Get.FindIcon(reference, let svg));
		Test.Assert(svg == cHeartSvg);

		// An @icon naming no vector image fails the cook rather than drawing nothing.
		fixture.StageSource("theme.sss", "@icon star \"{6dd1ae0e-fbe8-4c9b-8c9e-d10b727f4d84}\";\n.star { background: svg(star); }\n");
		fixture.Context.Output = fixture.CreateOutput("theme2", cThemeType);
		Test.Assert(builder.Build(asset, fixture.Context) case .Err);
	}
}
