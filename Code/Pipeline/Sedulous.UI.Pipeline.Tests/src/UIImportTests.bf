using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Importer;
using Sedulous.UI.Pipeline;

namespace Sedulous.UI.Pipeline.Tests;

/// The importer STAGES the dropped file into the sources tree and LINKS it. The text is never
/// embedded in the asset, so the file on disk stays the one true copy.
class UIImportTests
{
	[Test]
	public static void TheImporterLinksTheDroppedFileWithoutEmbeddingIt()
	{
		let fixture = scope UIPipelineFixture("import");

		// Loose files, living outside the project.
		let looseDocument = scope String();
		fixture.LoosePath("panel.sml", looseDocument);
		WriteFile(looseDocument, .((uint8*)UIStarterContent.cDocument.Ptr,
			UIStarterContent.cDocument.Length)).IgnoreError();
		let looseTheme = scope String();
		fixture.LoosePath("skin.sss", looseTheme);
		WriteFile(looseTheme, .((uint8*)UIStarterContent.cTheme.Ptr,
			UIStarterContent.cTheme.Length)).IgnoreError();

		let importer = scope UIFileImporter();
		let context = scope ImportContext(fixture.SourcesRoot);

		// The document: the link is set and the file is under the sources tree.
		let documentInstance = importer.Import(looseDocument, context, fixture.Cooked.RootGroup,
			null, null, null);
		Test.Assert(documentInstance case .Ok);
		{
			let object = documentInstance.Value.ReadObject();
			defer delete object;
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as UIDocumentAsset;
			Test.Assert(asset != null);
			Test.Assert(asset.FileName.Value == "panel.sml");
		}
		Test.Assert(fixture.SourceExists("panel.sml"));

		// The theme, the same way, and routed by extension to the OTHER asset type.
		let themeInstance = importer.Import(looseTheme, context, fixture.Cooked.RootGroup, null,
			null, null);
		Test.Assert(themeInstance case .Ok);
		{
			let object = themeInstance.Value.ReadObject();
			defer delete object;
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as UIThemeAsset;
			Test.Assert(asset != null);
			Test.Assert(asset.FileName.Value == "skin.sss");
		}
		Test.Assert(fixture.SourceExists("skin.sss"));
	}

	[Test]
	public static void ThePreviewMarkupRoundTripsOnTheAssetAndNeverReachesTheCook()
	{
		// The stylesheet page stores the markup it previews against on the theme, so a preview
		// context survives a session. That is EDITOR state: it persists in the source asset and
		// is deliberately absent from the cooked one, structurally rather than by convention,
		// since the cooked type has no field for it at all.
		let fixture = scope UIPipelineFixture("preview");
		fixture.StageSource("theme.sss", UIStarterContent.cTheme);

		let source = fixture.CreateOutput("theme_src", "Sedulous.UI.Pipeline.UIThemeAsset");
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set("theme.sss");
			asset.PreviewMarkup.Set("<Panel><Button text=\"Preview\"/></Panel>");
			Test.Assert(source.WriteObject(asset) case .Ok);
		}
		{
			let object = source.ReadObject();
			defer delete object;
			let loaded = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as UIThemeAsset;
			Test.Assert(loaded != null);
			Test.Assert(loaded.PreviewMarkup == "<Panel><Button text=\"Preview\"/></Panel>");
			Test.Assert(loaded.FileName.Value == "theme.sss", "the link is unaffected");
		}

		// The COOK: the product carries only the stylesheet, and the builder never reads the
		// preview at all.
		let product = fixture.CreateOutput("theme_cooked", "Sedulous.UI.Resource.UIThemeResource");
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set("theme.sss");
			asset.PreviewMarkup.Set("<Panel/>");
			fixture.Context.Output = product;
			Test.Assert(scope UIThemeAssetBuilder().Build(asset, fixture.Context) case .Ok);

			let object = product.ReadObject();
			defer delete object;
			let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as Sedulous.UI.Resource.UIThemeResource;
			Test.Assert(cooked != null);
			Test.Assert(cooked.StyleSheet == UIStarterContent.cTheme);
		}
	}
}
