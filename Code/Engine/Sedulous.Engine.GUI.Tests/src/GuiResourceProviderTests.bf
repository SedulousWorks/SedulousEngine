using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.Image;

namespace Sedulous.Engine.GUI.Tests;

/// The GUI's resources by asset guid: documents, sheets, vector images and textures, each only
/// as what it was cooked as, and a re-cook seen at the next poll.
class GuiResourceProviderTests
{
	[Test]
	public static void TheProviderAnswersDocumentsSheetsVectorImagesAndTexturesByGuidOnlyAsWhatTheyAre()
	{
		// DECLARED FIRST so it is freed LAST: the provider lets go of its bindings through it.
		let project = scope GuiTestProject("scratch_engine_gui_provider");
		let menu = project.Document("menu", "<Panel id=\"menu\"/>");
		let sheet = project.Sheet("game", "#menu { width: 10px; }");
		let icon = project.Vector("icon", "<svg width='8' height='8'><rect width='8' height='8'/></svg>");
		let map = project.Texture("map", 128, 64);
		let menuPath = GuiTestProject.Braced(menu, .. scope .());
		let sheetPath = sheet.ToString(.. scope .()); // the bare guid too
		let iconPath = GuiTestProject.Braced(icon, .. scope .());
		let mapPath = GuiTestProject.Braced(map, .. scope .());

		// Before the provider, so the sink it owns never outlives what it adds to.
		let told = scope List<ImageData>();
		let provider = scope GuiResourceProvider();
		let text = scope String();
		Test.Assert(!provider.LoadText(menuPath, text), "no resource manager yet");
		provider.SetResourceManager(project.Resources);
		provider.SetTextureSink(new (key, view) => { told.Add((view != null) ? key : null); });

		Test.Assert(provider.LoadText(menuPath, text));
		Test.Assert(text == "<Panel id=\"menu\"/>");
		text.Clear();
		Test.Assert(provider.LoadText(sheetPath, text));
		Test.Assert(text == "#menu { width: 10px; }");
		Test.Assert(!provider.LoadText("menu.xml", text), "a path is not a guid");
		Test.Assert(!provider.LoadText(iconPath, text), "a vector image is no text");

		let picture = provider.LoadSvg(iconPath);
		Test.Assert(picture != null);
		Test.Assert(provider.LoadSvg(iconPath) === picture, "parsed once");
		Test.Assert(provider.LoadSvg(GuiTestProject.Braced(sheet, .. scope .())) == null);

		let image = provider.LoadImage(mapPath);
		Test.Assert(image != null);
		Test.Assert(image.Width == 128);
		Test.Assert(image.Height == 64);
		Test.Assert(provider.LoadImage(mapPath) === image, "one key per texture");
		Test.Assert(told.Count == 1);
		Test.Assert(told[0] === image, "the renderers learn it");
		Test.Assert(provider.LoadImage(menuPath) == null);

		// Another project (or none): the key stops standing for the texture, and nothing resolves.
		provider.SetResourceManager(null);
		Test.Assert(told.Count == 2);
		Test.Assert(told[1] == null);
		Test.Assert(!provider.LoadText(menuPath, text));
		Test.Assert(provider.LoadImage(mapPath) == null);
	}

	[Test]
	public static void ASheetCookedAgainIsSeenAtTheNextPollOnce()
	{
		let project = scope GuiTestProject("scratch_engine_gui_poll");
		let sheet = project.Sheet("game", "#a { width: 1px; }");
		let sheetPath = GuiTestProject.Braced(sheet, .. scope .());
		let provider = scope GuiResourceProvider();
		provider.SetResourceManager(project.Resources);
		defer provider.SetResourceManager(null); // before the project goes

		let text = scope String();
		Test.Assert(provider.LoadText(sheetPath, text));
		Test.Assert(!provider.Poll());
		project.RewriteSheet(sheet, "#a { width: 2px; }");
		Test.Assert(provider.Poll());
		text.Clear();
		Test.Assert(provider.LoadText(sheetPath, text));
		Test.Assert(text == "#a { width: 2px; }");
		Test.Assert(!provider.Poll());
	}

	[Test]
	public static void AGuidIsReadBracedOrBareAndNeverNil()
	{
		let id = Guid.Create();
		Test.Assert(GuiResourceProvider.ParseGuid(GuiTestProject.Braced(id, .. scope .()), let braced) && (braced == id));
		Test.Assert(GuiResourceProvider.ParseGuid(id.ToString(.. scope .()), let bare) && (bare == id));
		Test.Assert(!GuiResourceProvider.ParseGuid("menu.xml", ?));
		Test.Assert(!GuiResourceProvider.ParseGuid("{00000000-0000-0000-0000-000000000000}", ?));
	}
}
