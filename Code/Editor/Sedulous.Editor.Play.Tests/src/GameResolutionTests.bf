using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Play.Tests;

/// The Game tab's resolution dropdown and how it puts the game on its target.
class GameResolutionTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.001f * Math.Max(1.0f, Math.Abs(b));

	[Test]
	public static void TheProjectsFirstThenThePresetsThePreviewsThePanel()
	{
		// Nothing at all: the project's entry (the panel's size) and the panel's.
		{
			let bare = scope List<GameResolutionChoice>();
			defer ClearAndDeleteItems(bare);
			GameResolution.Collect(null, null, null, bare);
			Test.Assert(bare.Count == 2);
			Test.Assert((bare[0].Key == GameResolution.cProjectKey) && (bare[0].Label == "Project (panel size)") && (bare[0].Width == 0));
			Test.Assert(bare[1].Key == GameResolution.cPanelKey);
		}

		let settings = scope ProjectSettings();
		settings.RenderWidth = 640;
		settings.RenderHeight = 360;
		let presets = scope ExportPresetSet();
		let desktop = new ExportPreset(); // draws at the project's size: not offered
		desktop.Name.Set("Desktop");
		let handheld = new ExportPreset();
		handheld.Name.Set("Handheld");
		handheld.OverridesRender = true;
		handheld.RenderWidth = 1280;
		handheld.RenderHeight = 800;
		presets.Presets.Add(desktop);
		presets.Presets.Add(handheld);
		let previews = scope GamePreviewSettings();
		previews.Presets.Add(new .("QHD", 2560, 1440));
		previews.Presets.Add(new .("Broken", 0, 1440)); // skipped

		let choices = scope List<GameResolutionChoice>();
		defer ClearAndDeleteItems(choices);
		GameResolution.Collect(settings, presets, previews, choices);
		Test.Assert(choices.Count == 4);
		Test.Assert((choices[0].Label == "Project 640x360") && (choices[0].Width == 640));
		Test.Assert((choices[1].Key == "export:Handheld") && (choices[1].Label == "Handheld 1280x800"));
		Test.Assert((choices[2].Key == "preset:QHD") && (choices[2].Height == 1440));
		Test.Assert((choices[3].Key == GameResolution.cPanelKey) && (choices[3].Width == 0));
		let before = GameResolution.Signature(choices, settings, .. scope .());

		// A preset held its own way (a phone-facing Web preset): offered at the project's size,
		// named with its orientation, which the tab previews it with.
		let web = new ExportPreset();
		web.Name.Set("Web");
		web.OverridesOrientation = true;
		web.Orientation = .Landscape;
		presets.Presets.Add(web);
		let held = scope List<GameResolutionChoice>();
		defer ClearAndDeleteItems(held);
		GameResolution.Collect(settings, presets, previews, held);
		Test.Assert(held.Count == 5);
		Test.Assert((held[2].Key == "export:Web") && (held[2].Label == "Web 640x360, landscape"), held[2].Label);
		Test.Assert((held[2].Width == 640) && held[2].OverridesOrientation && (held[2].Orientation == .Landscape));
		Test.Assert(!held[1].OverridesOrientation, "the handheld keeps the project's");
		// The signature follows an orientation too.
		Test.Assert(GameResolution.Signature(held, settings, .. scope .()) != before);
	}

	/// The Game tab puts the game on its target as the player puts it in a window, so the phone
	/// preview (a portrait 720x1560 screen) turns a landscape game as a phone does.
	[Test]
	public static void TheGameOnAPreviewedPhoneIsTurnedAsAPhoneTurnsIt()
	{
		let w = GameResolution.cPhonePreviewWidth;
		let h = GameResolution.cPhonePreviewHeight;
		Test.Assert(h * 9 == w * 19 + w / 2, "9 by 19.5");

		// A landscape game with no resolution of its own: the phone's pixels, turned.
		let turned = GameResolution.GameFitOn(w, h, 0, 0, .Letterbox, .Landscape);
		Test.Assert(turned.Rotation == .ThreeQuarter);
		Test.Assert(Near(turned.ContentSize.X, 1560) && Near(turned.ContentSize.Y, 720) && (turned.Mode == .Stretch));

		// With one: that resolution, by its fit, turned.
		let sized = GameResolution.GameFitOn(w, h, 1280, 720, .Letterbox, .Landscape);
		Test.Assert((sized.Rotation == .ThreeQuarter) && Near(sized.ContentSize.X, 1280) && (sized.Mode == .Letterbox));

		// Held any way, or on a target of its own shape: never turned.
		Test.Assert(GameResolution.GameFitOn(w, h, 0, 0, .Letterbox, .Any).Rotation == .None);
		let panel = GameResolution.GameFitOn(1600, 900, 0, 0, .Letterbox, .Landscape);
		Test.Assert((panel.Rotation == .None) && Near(panel.ContentSize.X, 1600));
	}

	/// The Game tab's settings moved from Editor.Scene with it: a project store saved before the
	/// move, its name and type id the old ones, still loads the resolution chosen.
	[Test]
	public static void AResolutionChosenBeforeTheTabsMoveStillLoads()
	{
		PlayEditorSerializables.Register();
		let store = scope Settings();
		store.Section<GamePageSettings>().ResolutionKey.Set("preset:Phone");
		store.Section<GamePageSettings>().PhonePreview = true;
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);

		// The file as the build before the move wrote it.
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		let current = "Sedulous.Editor.Play.GamePageSettings";
		let former = "Sedulous.Editor.Scene.GamePageSettings";
		let currentId = scope $"{Sedulous.Core.Serialization.TypeIdOf(current)}";
		Test.Assert(text.Contains(currentId), scope $"the id is written as {currentId}: {text}");
		text.Replace(currentId, scope $"{Sedulous.Core.Serialization.TypeIdOf(former)}");
		text.Replace(current, former);
		let old = scope MemoryStream();
		old.Write(.((uint8*)text.Ptr, text.Length));
		old.Seek(0, .Begin);

		let loaded = scope Settings();
		Test.Assert(loaded.Load(old, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		let read = loaded.Find<GamePageSettings>();
		Test.Assert((read != null) && (read.ResolutionKey == "preset:Phone") && read.PhonePreview);
	}
}
