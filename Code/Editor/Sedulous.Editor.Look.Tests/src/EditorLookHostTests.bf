using System;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Look;
using Sedulous.Editor.Look.TestSupport;

namespace Sedulous.Editor.Look.Tests;

/// The look both the editor and the project manager stand on: the sheet assembled from the
/// repository's own files (the editor's sheet, the chosen density's after it, the accent as an
/// input last) for every density; the user's theme overrides after all of it, winning the cascade
/// and gone when the file goes; and a host with no device that opens nothing and does nothing.
static class EditorLookHostTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(System.IO.Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	/// Written through a mount, which makes the folders on the way.
	private static void Write(StringView root, StringView relative, StringView text)
	{
		let fs = scope NativeFileSystem(root);
		Test.Assert(fs.Save(relative, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	[Test]
	public static void EachDensitysSheetIsTheEditorsThenTheDensitysThenTheAccentFromTheRepositorysData()
	{
		let data = scope String();
		Test.Assert(EditorData.Root(data));
		let resources = scope EditorResources(data, EditorLookHost.cEditorFolder);
		let editor = scope String();
		Test.Assert(resources.LoadText(EditorLookHost.cSheetPath, editor));
		Test.Assert(editor.Contains("@import \"Editor/tokens.css\";"), "the editor's sheet over its tokens");
		// Each density's row height (Data/Editor/density-<name>.css), in EditorLook.Densities' order.
		StringView[3] rows = .("--row: 22px", "--row: 26px", "--row: 30px");
		for (int i < EditorLook.Densities.Count)
		{
			let look = scope EditorLook();
			look.Density.Set(EditorLook.Densities[i]);
			look.Accent.Set("#6d5bd8");
			let text = EditorLookHost.SheetFor(resources, look, .. scope .());
			Test.Assert(text.StartsWith(editor), "the editor's sheet first");
			let density = text.IndexOf(rows[i]);
			let accent = text.IndexOf(":root { --accent-input: #6d5bd8; }");
			Test.Assert((density > editor.Length) && (accent > density), scope String(EditorLook.Densities[i]));
			for (int other < rows.Count)
				Test.Assert((other == i) || !text.Contains(rows[other]), "one density's sheet, the chosen one");
			let sheet = scope StyleSheet();
			CSSParser.Parse(text, EditorLookHost.cSheetPath, sheet);
			Test.Assert(sheet.RuleCount > 1, "it parses into the editor's rules");
		}

		// The fixture tests style with is the same sheet, the default density's.
		let fixture = scope EditorSheet();
		Test.Assert(fixture.Styles != null);
	}

	/// The colour a `.frame` resolves to under `text`.
	private static void FrameColor(StringView text, String outColor)
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(text, EditorLookHost.cSheetPath, sheet);
		let frame = new UIWidget();
		defer frame.ReleaseRef();
		frame.AddClass("frame");
		let style = scope ResolvedStyle();
		sheet.Resolve(frame, style);
		outColor.Set(style.Get("color"));
	}

	[Test]
	public static void AThemeOverrideComesAfterTheAccentAndWinsTheCascadeUntilItsFileGoes()
	{
		let root = Scratch("scratch_look_theme", .. scope .());
		defer RemoveDirectoryRecursive(root);
		Write(root, "Editor/editor.css", ".frame { --surface: #ffffff; color: var(--surface); }");
		Write(root, "Editor/density-compact.css", ":root { --row: 22px; }");
		let resources = scope EditorResources(root);
		let folder = PathJoin(root, "user-theme", .. scope .());
		Test.Assert(CreateDirectory(folder));
		let theme = scope EditorResources(folder); // empty, as on a first run
		let look = scope EditorLook();

		let plain = EditorLookHost.SheetFor(resources, look, theme, .. scope .());
		Test.Assert(FrameColor(plain, .. scope .()) == "#ffffff", "no file: the editor's own");

		Write(folder, EditorLookHost.cThemeOverridesPath, ".frame { --surface: #000000; }\n:root { --accent-input: #ff0000; }");
		Test.Assert(theme.Poll(), "the new file is seen");
		let overridden = EditorLookHost.SheetFor(resources, look, theme, .. scope .());
		let inputs = overridden.IndexOf("--accent-input: #2f6fdf");
		let theirs = overridden.IndexOf("--accent-input: #ff0000");
		Test.Assert((inputs >= 0) && (inputs < theirs), "after the look's inputs, so the user's own accent wins");
		Test.Assert(FrameColor(overridden, .. scope .()) == "#000000", "the user's token wins the cascade");

		Test.Assert(System.IO.File.Delete(PathJoin(folder, EditorLookHost.cThemeOverridesPath, .. scope .())) case .Ok);
		Test.Assert(theme.Poll());
		let removed = EditorLookHost.SheetFor(resources, look, theme, .. scope .());
		Test.Assert(FrameColor(removed, .. scope .()) == "#ffffff", "removed: the editor's own again");
	}

	[Test]
	public static void WithNoDeviceItOpensNoInterfaceAndItsCallsDoNothing()
	{
		let host = scope EditorLookHost();
		let look = scope EditorLook();
		look.Density.Set("comfortable");
		Test.Assert(!host.Open(null, null, "unused", look));
		Test.Assert(!host.IsOpen);
		Test.Assert((host.Host == null) && (host.Root == null) && (host.Resources == null) && (host.Fonts == null));
		Test.Assert(host.LoadMarkup("Editor/Shell.xml") == null);
		Test.Assert(!host.LoadText(EditorLookHost.cSheetPath, scope .()));
		host.Update(2.0f);
		host.Attach(null);
		// The look is kept for when it opens, copied.
		host.SetLook(look);
		Test.Assert(host.Look.Density == "comfortable");
		Test.Assert(host.Look !== look);
		let desc = EditorLookHost.WindowDesc();
		Test.Assert((desc.BufferCount == 3) && (desc.PresentMode == .Fifo));
		host.Detach();
		host.Close();
		host.Close(); // again: nothing left to let go of
	}
}
