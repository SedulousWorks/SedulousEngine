using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// The manifest a project and a distribution are both described by.
///
/// The [Serializable] generator walks the declaration, so what is on the wire follows from
/// the field ORDER and NAMES. These pin both, because a rename or a reorder would change
/// the document silently.
class ProjectManifestTests
{
	private const String kScratch = "scratch_engine_project";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	/// Sorted last, so the manifests these cases write do not survive the run. A suite that
	/// leaves them behind is a suite whose output gets committed by accident.
	[Test]
	public static void ZzCleanup()
	{
		RemoveDirectoryRecursive(kScratch);
	}

	/// A version 9 manifest, which carried the old UI's theme and loading document, still opens:
	/// the two are passed by, every other setting reads, and it saves as version 10 without them.
	[Test]
	public static void AVersion9ManifestStillReadsItsOldUiSettingsDropped()
	{
		FreshScratch();
		const String cVersion9 = """
			<root>
				<array name="dataVersions" count="1">
					<u64 name="type">15697994609334965484</u64>
					<u32 name="version">9</u32>
				</array>
				<object>
					<string name="name">Old</string>
					<string name="engineVersion">0.1.0</string>
					<string name="defaultSceneId">abf41c6a-3a62-4a4f-830f-47fb88f610ff</string>
					<string name="defaultScene">Scenes/Start</string>
					<string name="startupScript"/>
					<string name="nativeModule"/>
					<string name="defaultInputMapId">00000000-0000-0000-0000-000000000000</string>
					<string name="defaultBusLayoutId">00000000-0000-0000-0000-000000000000</string>
					<string name="defaultUiThemeId">11111111-1111-1111-1111-111111111111</string>
					<string name="startupScriptId">00000000-0000-0000-0000-000000000000</string>
					<string name="defaultUiFontId">23da25e1-47fe-2044-a727-d7fbcde40a8f</string>
					<string name="loadingDocumentId">22222222-2222-2222-2222-222222222222</string>
					<u32 name="renderMsaaSamples">4</u32>
				</object>
			</root>
			""";
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(fs.Save("Project.xml", .((uint8*)cVersion9.Ptr, cVersion9.Length)) case .Ok);
		let settings = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, settings, "Project.xml") case .Ok);
		Test.Assert(settings.Name == "Old");
		Test.Assert(settings.DefaultSceneId == Guid.Parse("abf41c6a-3a62-4a4f-830f-47fb88f610ff").Get());
		Test.Assert(settings.DefaultUiFontId == Guid.Parse("23da25e1-47fe-2044-a727-d7fbcde40a8f").Get(), "after the dropped theme");
		Test.Assert(settings.RenderMsaaSamples == 4, "after the dropped loading document");
		Test.Assert(!settings.GuiLoadingDocumentId.IsSet, "the old UI's document is not the GUI's");

		Test.Assert(ProjectManifest.Save(fs, settings, "Project.xml") case .Ok);
		let saved = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(kScratch, "Project.xml", .. scope .()), saved) case .Ok);
		Test.Assert(saved.Contains("<u32 name=\"version\">10</u32>"));
		Test.Assert(!saved.Contains("defaultUiThemeId") && !saved.Contains("name=\"loadingDocumentId\""));
	}

	/// A version 10 manifest naming a native module (a library path, before a game's native code
	/// was a package) still opens: the path is passed by and lost, every setting after it reads,
	/// no plugin entry stands in for it, and a save writes the manifest without it.
	[Test]
	public static void AVersion10ManifestsNativeModuleIsPassedByAndDropped()
	{
		FreshScratch();
		const String cVersion10 = """
			<root>
				<array name="dataVersions" count="1">
					<u64 name="type">15697994609334965484</u64>
					<u32 name="version">10</u32>
				</array>
				<object>
					<string name="name">Old</string>
					<string name="engineVersion">0.1.0</string>
					<string name="defaultSceneId">abf41c6a-3a62-4a4f-830f-47fb88f610ff</string>
					<string name="defaultScene">Scenes/Start</string>
					<string name="startupScript"/>
					<string name="nativeModule">Native/libOldGame.so</string>
					<string name="defaultInputMapId">7c0d2a51-0f6e-4b8e-9a3d-5e2f1c4b6a70</string>
					<string name="defaultBusLayoutId">00000000-0000-0000-0000-000000000000</string>
					<string name="startupScriptId">00000000-0000-0000-0000-000000000000</string>
					<string name="defaultUiFontId">00000000-0000-0000-0000-000000000000</string>
					<u32 name="renderMsaaSamples">2</u32>
				</object>
			</root>
			""";
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(fs.Save("Project.xml", .((uint8*)cVersion10.Ptr, cVersion10.Length)) case .Ok);
		let settings = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, settings, "Project.xml") case .Ok);
		Test.Assert(settings.Name == "Old");
		Test.Assert(settings.DefaultInputMapId == Guid.Parse("7c0d2a51-0f6e-4b8e-9a3d-5e2f1c4b6a70").Get(), "after the dropped path");
		Test.Assert(settings.RenderMsaaSamples == 2);
		Test.Assert(settings.Plugins.IsEmpty, "the path is lost, not migrated");

		Test.Assert(ProjectManifest.Save(fs, settings, "Project.xml") case .Ok);
		let saved = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(kScratch, "Project.xml", .. scope .()), saved) case .Ok);
		Test.Assert(saved.Contains("<u32 name=\"version\">10</u32>"));
		Test.Assert(!saved.Contains("nativeModule"));
	}

	/// A copy goes through the settings' own serialization, so it carries every field, the
	/// ones added after it was written too: the two manifests are the same document.
	[Test]
	public static void ACopyCarriesEverySetting()
	{
		FreshScratch();

		let from = scope ProjectSettings();
		from.Name.Set("Demo");
		from.DefaultSceneId = .(0x11223344, 0x5566, 0x7788, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00);
		from.DefaultScene.Set("Scenes/Main");
		from.GuiLoadingDocumentId = .(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		from.RenderMsaaSamples = 4;
		from.UiFontIds.Add(.(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9));
		from.RenderWidth = 1280;
		from.RenderHeight = 800;
		from.RenderFit = .Crop;
		from.WindowMode = .Fullscreen;
		from.WindowResizable = false;
		from.Orientation = .Landscape;

		let to = scope ProjectSettings();
		Test.Assert(ProjectManifest.Copy(from, to) case .Ok);
		Test.Assert((to.GuiLoadingDocumentId == from.GuiLoadingDocumentId) && (to.RenderMsaaSamples == 4));
		Test.Assert((to.UiFontIds.Count == 1) && (to.RenderFit == .Crop) && (to.WindowMode == .Fullscreen) && !to.WindowResizable);
		Test.Assert(to.Orientation == .Landscape);

		// Field by field, whatever fields there are: both saved, the documents the same.
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, from, "from.xml") case .Ok);
		Test.Assert(ProjectManifest.Save(fs, to, "to.xml") case .Ok);
		let fromText = File.ReadAllText(scope $"{kScratch}/from.xml", .. scope .());
		let toText = File.ReadAllText(scope $"{kScratch}/to.xml", .. scope .());
		Test.Assert(!fromText.IsEmpty && (fromText == toText), "the copy is the same document");
	}

	[Test]
	public static void AManifestRoundTripsThroughTheDefaultFileName()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.Name.Set("Demo");
		written.DefaultSceneId = .(0x11223344, 0x5566, 0x7788, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00);
		written.DefaultScene.Set("Scenes/Main");
		written.StartupScript.Set("Scripts/Game");
		written.RenderMsaaSamples = 4;

		{
			let fs = scope NativeFileSystem(kScratch);
			Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		}

		let read = scope ProjectSettings();
		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Load(fs, read) case .Ok);

		Test.Assert(read.Name == "Demo");
		Test.Assert(read.DefaultSceneId == written.DefaultSceneId);
		Test.Assert(read.DefaultScene == "Scenes/Main");
		Test.Assert(read.StartupScript == "Scripts/Game");
		Test.Assert(read.RenderMsaaSamples == 4);
	}

	/// The other UI fonts round trip, and a manifest saved before they existed (no
	/// uiFontIds key) still loads, with none: every project saved until now is one.
	[Test]
	public static void TheUiFontsRoundTripAndAnOlderManifestStillLoads()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		let written = scope ProjectSettings();
		written.Name.Set("Fonts");
		let title = Guid.Create();
		let mono = Guid.Create();
		written.UiFontIds.Add(title);
		written.UiFontIds.Add(mono);
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
			Test.Assert((read.UiFontIds.Count == 2) && (read.UiFontIds[0] == title) && (read.UiFontIds[1] == mono));
		}

		// The same manifest as an older engine wrote it: no uiFontIds element at all.
		let path = scope $"{kScratch}/{ProjectLayout.ManifestFile}";
		let text = scope String();
		Test.Assert(File.ReadAllText(path, text) case .Ok);
		let start = text.IndexOf("<array name=\"uiFontIds\"");
		Test.Assert(start >= 0, text);
		let end = text.IndexOf("</array>", start) + "</array>".Length;
		text.Remove(start, end - start);
		Test.Assert(File.WriteAllText(path, text) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok, "an older manifest loads");
			Test.Assert((read.Name == "Fonts") && read.UiFontIds.IsEmpty);
		}
	}

	/// The engine GUI's sheets round trip in their order (the game's over the shared) with its
	/// loading screen, and a manifest saved before either existed still loads, with none.
	[Test]
	public static void TheGuiSheetsKeepTheirOrderWithTheGuiLoadingScreenAndAnOlderManifestStillLoads()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);

		let written = scope ProjectSettings();
		written.Name.Set("Sheets");
		let shared = Guid.Create();
		let game = Guid.Create();
		let splash = Guid.Create();
		written.GuiStyleSheetIds.Add(shared);
		written.GuiStyleSheetIds.Add(game);
		written.GuiLoadingDocumentId = splash;
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
			Test.Assert((read.GuiStyleSheetIds.Count == 2) && (read.GuiStyleSheetIds[0] == shared) && (read.GuiStyleSheetIds[1] == game));
			Test.Assert(read.GuiLoadingDocumentId == splash);
		}

		// The same manifest as an older engine wrote it: neither element.
		let path = scope $"{kScratch}/{ProjectLayout.ManifestFile}";
		let text = scope String();
		Test.Assert(File.ReadAllText(path, text) case .Ok);
		void Cut(StringView open, StringView close)
		{
			let start = text.IndexOf(open);
			Test.Assert(start >= 0, text);
			let end = text.IndexOf(close, start) + close.Length;
			text.Remove(start, end - start);
		}
		Cut("<array name=\"guiStyleSheetIds\"", "</array>");
		Cut("<string name=\"guiLoadingDocumentId\"", "</string>");
		Test.Assert(File.WriteAllText(path, text) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok, "an older manifest loads");
			Test.Assert((read.Name == "Sheets") && read.GuiStyleSheetIds.IsEmpty && !read.GuiLoadingDocumentId.IsSet);
		}
	}

	/// The orientation is appended: a manifest an older engine wrote, without it, reads Any (the
	/// game takes the window's shape, as before), and one that says Landscape keeps it.
	[Test]
	public static void AnOlderManifestReadsAnyOrientation()
	{
		FreshScratch();
		let fs = scope NativeFileSystem(kScratch);
		let written = scope ProjectSettings();
		written.Name.Set("Turned");
		written.Orientation = .Landscape;
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
			Test.Assert(read.Orientation == .Landscape);
		}

		// The same manifest without its orientation element.
		let path = scope $"{kScratch}/{ProjectLayout.ManifestFile}";
		let text = scope String();
		Test.Assert(File.ReadAllText(path, text) case .Ok);
		let start = text.IndexOf("name=\"orientation\"");
		Test.Assert(start >= 0, text);
		let open = text.LastIndexOf('<', start);
		let end = text.IndexOf('>', text.IndexOf("</", start)) + 1;
		text.Remove(open, end - open);
		Test.Assert(!text.Contains("orientation"), text);
		Test.Assert(File.WriteAllText(path, text) case .Ok);
		{
			let read = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, read) case .Ok, "an older manifest loads");
			Test.Assert((read.Name == "Turned") && (read.Orientation == .Any));
		}
	}

	/// Every save re-stamps the engine that wrote it, so a launcher can route on it.
	[Test]
	public static void SavingStampsTheEngineVersion()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.EngineVersion.Set("0.0.0-stale");

		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, written) case .Ok);
		Test.Assert(written.EngineVersion == EngineVersion.String, "re-stamped in place");

		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read) case .Ok);
		Test.Assert(read.EngineVersion == EngineVersion.String);
	}

	/// This engine's release downloads come from its own version's release, tagged with the
	/// version and its label.
	[Test]
	public static void ThisEnginesReleaseDownloadsComeFromItsOwnVersionsRelease()
	{
		Test.Assert(EngineVersion.ReleaseRepository.Contains('/')); // owner/name
		let url = EngineVersion.ReleaseDownloadUrl("samples.json", .. scope String());
		let expected = scope String()..AppendF("https://github.com/{}/releases/download/v{}/samples.json",
			EngineVersion.ReleaseRepository, EngineVersion.Display);
		Test.Assert(url == expected);
		Test.Assert(url.StartsWith("https://github.com/"));
	}

	/// The version a person reads is the compared one with the release's label, if any; the
	/// compared one stays numbers (its parts the three constants); a build names itself by it,
	/// its build number or as a local build, and its stamp.
	[Test]
	public static void TheDisplayVersionCarriesTheLabelAndABuildsIdentityItsNumberOrLocal()
	{
		let display = scope String(EngineVersion.String);
		if (!StringView(EngineVersion.Label).IsEmpty)
			display.AppendF("-{}", EngineVersion.Label);
		Test.Assert(EngineVersion.Display == display, EngineVersion.Display);
		Test.Assert(EngineVersion.String == scope String()..AppendF("{}.{}.{}", EngineVersion.Major, EngineVersion.Minor, EngineVersion.Patch));
		for (let c in EngineVersion.String.RawChars)
			Test.Assert(c.IsDigit || (c == '.'), "the compared version is numbers alone");

		Test.Assert(EngineVersion.BuildIdentity("2026-11-05T15:03:00Z", 3, .. scope .()) == scope String()..AppendF("{} (build 3, 2026-11-05T15:03:00Z)", display));
		Test.Assert(EngineVersion.BuildIdentity("2026-11-05T15:03:00Z", 0, .. scope .()) == scope String()..AppendF("{} (local build, 2026-11-05T15:03:00Z)", display));
		// This build's: its number's form, and the test executable's stamp.
		let stamp = EngineVersion.ExecutableStamp(.. scope .());
		Test.Assert(!stamp.IsEmpty && (stamp != "unknown"), "a desktop test reads its executable's time");
		Test.Assert(stamp.EndsWith('Z'));
		let identity = EngineVersion.BuildIdentity(.. scope .());
		Test.Assert(identity.StartsWith(scope String()..AppendF("{} (", display)));
		Test.Assert(identity.EndsWith(scope String()..AppendF(", {})", stamp)));
		Test.Assert(identity.Contains((EngineVersion.BuildNumber == 0) ? "(local build, " : "(build "));
	}

	/// A distribution manifest is the same payload under another name, which is the whole
	/// reason the file name is a parameter.
	[Test]
	public static void TheDistributionManifestIsTheSamePayload()
	{
		FreshScratch();

		let written = scope ProjectSettings();
		written.Name.Set("Shipped");
		written.RenderMsaaSamples = 2;

		let fs = scope NativeFileSystem(kScratch);
		Test.Assert(ProjectManifest.Save(fs, written, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(fs.Exists(ProjectLayout.DistManifestFile));
		Test.Assert(!fs.Exists(ProjectLayout.ManifestFile), "the default name was not used");

		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read, ProjectLayout.DistManifestFile) case .Ok);
		Test.Assert(read.Name == "Shipped");
		Test.Assert(read.RenderMsaaSamples == 2);
	}

	/// An absent manifest is NotFound rather than a blank one, so a caller can tell the
	/// difference between a project with defaults and no project at all.
	[Test]
	public static void AMissingManifestIsNotFound()
	{
		FreshScratch();

		let fs = scope NativeFileSystem(kScratch);
		let read = scope ProjectSettings();
		Test.Assert(ProjectManifest.Load(fs, read) case .Err(.NotFound));
	}
}
