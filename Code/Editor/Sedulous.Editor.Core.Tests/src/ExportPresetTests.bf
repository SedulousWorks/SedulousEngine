using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The export presets and roots: the files round trip and refuse another data version, a
/// preset's legacy template id is read and dropped, its fields describe themselves through
/// reflection, the presets controller edits with unique names, the roots set toggles
/// idempotently; and the file copy an export stages with keeps what was executable.
static class ExportPresetTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);
	}

	private static void SaveText(StringView dir, StringView name, StringView text)
	{
		let path = PathJoin(dir, name, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	[Test]
	public static void ThePresetSetRoundTripsThroughExportPresetsXml()
	{
		let dir = Scratch("scratch_presets", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		let absent = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, absent) case .Err(.NotFound));

		let defaults = scope ExportPresetSet();
		ExportPresetsFile.Defaults(defaults);
		Test.Assert((defaults.Presets.Count == 1) && (defaults.Presets[0].Platform == BuildLayout.HostPlatformName));

		let written = scope ExportPresetSet();
		let a = new ExportPreset();
		a.Name.Set("Linux Desktop");
		a.Platform.Set("Linux64");
		a.OutputSubdir.Set("Linux64");
		let b = new ExportPreset();
		b.Name.Set("Windows Desktop");
		b.Platform.Set("Win64");
		b.Config.Set("Debug");
		b.StageSymbols = true;
		b.PruneToReachable = true;
		b.PlayerName.Set("MyGame.exe");
		b.OutputSubdir.Set("Win64");
		b.AdditionalFiles.Add(new String("icon.ico"));
		b.AdditionalFiles.Add(new String("config.xml"));
		b.OverridesOrientation = true;
		b.Orientation = .Landscape;
		b.IncludeShaderSource = true;
		written.Presets.Add(a);
		written.Presets.Add(b);
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);

		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Ok);
		Test.Assert(loaded.Presets.Count == 2);
		Test.Assert((loaded.Presets[0].Name == "Linux Desktop") && loaded.Presets[0].PlayerName.IsEmpty && !loaded.Presets[0].PruneToReachable);
		let win = loaded.Find("Windows Desktop");
		Test.Assert(win != null);
		Test.Assert((win.Platform == "Win64") && (win.Config == "Debug") && win.StageSymbols && win.PruneToReachable);
		Test.Assert(win.PlayerName == "MyGame.exe");
		Test.Assert((win.AdditionalFiles.Count == 2) && (win.AdditionalFiles[0] == "icon.ico") && (win.AdditionalFiles[1] == "config.xml"));
		Test.Assert(win.OverridesOrientation && (win.Orientation == .Landscape));
		Test.Assert(!loaded.Presets[0].OverridesOrientation && (loaded.Presets[0].Orientation == .Any));
		Test.Assert(win.IncludeShaderSource, "keeping shader source round trips");
		Test.Assert(!loaded.Presets[0].IncludeShaderSource, "no shader source by default");
		Test.Assert(loaded.Find("nope") == null);
	}

	/// A preset that named a template (every sample's did) still reads, its template id dropped
	/// and the fields around it intact, and the next save writes the slot empty.
	[Test]
	public static void ALegacyTemplateIdIsReadAndDropped()
	{
		let dir = Scratch("scratch_presets_legacy", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		let written = scope ExportPresetSet();
		let preset = new ExportPreset();
		preset.Name.Set("Steam Deck");
		preset.Platform.Set("Linux64");
		preset.TemplateId.Set("sedulous-steamdeck-release-0.1.0");
		preset.PlayerName.Set("SkyHopper");
		written.Presets.Add(preset);
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .()), bytes) case .Ok);
		Test.Assert(StringView((char8*)bytes.Ptr, bytes.Count).Contains("sedulous-steamdeck-release-0.1.0"), "the file carries the id, as an older one does");

		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Ok);
		let deck = loaded.Find("Steam Deck");
		Test.Assert(deck != null);
		Test.Assert(deck.TemplateId.IsEmpty, "dropped as it is read");
		Test.Assert((deck.Platform == "Linux64") && (deck.PlayerName == "SkyHopper"), "the fields around the slot read as written");
		Test.Assert(ExportPresetsFile.Save(root, loaded) case .Ok);
		bytes.Clear();
		Test.Assert(ReadFile(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .()), bytes) case .Ok);
		Test.Assert(!StringView((char8*)bytes.Ptr, bytes.Count).Contains("sedulous-steamdeck-release-0.1.0"), "saved again: the slot is empty");
	}

	/// The binary form is positional: the legacy slot stays where it was, so a preset stored
	/// with a template id reads every later field as written, the id dropped.
	[Test]
	public static void TheLegacySlotKeepsTheBinaryFormInPlace()
	{
		let preset = scope ExportPreset();
		preset.Name.Set("Windows Desktop");
		preset.Platform.Set("Win64");
		preset.TemplateId.Set("sedulous-win64-release-0.1.0");
		preset.PlayerName.Set("MyGame.exe");
		preset.Config.Set("Debug");
		preset.StageSymbols = true;
		preset.IncludeShaderSource = true;
		let stream = scope Sedulous.Core.IO.MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			ISerializable serializable = preset;
			serializable.Serialize(ar);
		}
		stream.Seek(0, .Begin);
		let read = scope ExportPreset();
		{
			let ar = scope BinarySerializer(stream, .Read);
			ISerializable serializable = read;
			serializable.Serialize(ar);
		}
		Test.Assert(read.TemplateId.IsEmpty, "the id dropped");
		Test.Assert((read.Name == "Windows Desktop") && (read.Platform == "Win64") && (read.PlayerName == "MyGame.exe"));
		Test.Assert((read.Config == "Debug") && read.StageSymbols && read.IncludeShaderSource, "every field after the slot in place");
	}

	/// A preset describes its fields through reflection, each labelled, the sizes with their
	/// range: the MCP preset tools set them through it.
	[Test]
	public static void APresetDescribesItsFieldsThroughReflection()
	{
		let fields = scope List<System.Reflection.FieldInfo>();
		SettingFields.Of(typeof(ExportPreset), fields);
		let keys = scope String();
		for (let field in fields)
		{
			if (!keys.IsEmpty)
				keys.Append(",");
			SettingFields.Key(field, keys);
			Test.Assert(!SettingFields.Setting(field).Value.Label.IsEmpty);
			if (field.Name == "AdditionalFiles")
				Test.Assert(SettingFields.KindOf(field, let kind) && (kind == .TextList));
			if (field.Name == "RenderWidth")
			{
				SettingFields.CountRange(field, let least, let most);
				Test.Assert((least == 0) && (most == 16384));
			}
			if (field.Name == "WindowHeight")
			{
				SettingFields.CountRange(field, let least, let most);
				Test.Assert((least == 1) && (most == 16384));
			}
		}
		Test.Assert(keys == "name,platform,playerName,outputSubdir,additionalFiles,config,stageSymbols,pruneToReachable,overridesRender,renderWidth,renderHeight,renderFit,overridesWindow,windowWidth,windowHeight,windowMode,windowResizable,overridesOrientation,orientation,includeShaderSource", keys);
	}

	[Test]
	public static void AnotherDataVersionIsRefusedNotDefaulted()
	{
		let dir = Scratch("scratch_presets_v1", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let root = scope NativeFileSystem(dir);
		// A file saved at the current version, its version rewritten: the envelope refuses.
		let written = scope ExportPresetSet();
		let preset = new ExportPreset();
		preset.Name.Set("Legacy");
		written.Presets.Add(preset);
		Test.Assert(ExportPresetsFile.Save(root, written) case .Ok);
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(dir, ExportPresetsFile.cFileName, .. scope .()), bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		let marker = "<u32 name=\"version\">";
		let at = text.IndexOf(marker);
		Test.Assert(at >= 0);
		let close = text.IndexOf('<', at + marker.Length);
		text.Remove(at + marker.Length, close - (at + marker.Length));
		text.Insert(at + marker.Length, "1");
		SaveText(dir, ExportPresetsFile.cFileName, text);
		let loaded = scope ExportPresetSet();
		Test.Assert(ExportPresetsFile.Load(root, loaded) case .Err);
	}

	[Test]
	public static void ThePresetsControllerLoadsDefaultsEditsWithUniqueNamesAndSaves()
	{
		let dir = Scratch("scratch_presets_controller", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let fs = scope NativeFileSystem(dir);
		let controller = scope ExportPresetsController();
		controller.Load(fs);
		Test.Assert(controller.Count == 1, "no file: the host default");
		let preset = scope ExportPreset();
		preset.Name.Set("Steam");
		preset.Platform.Set("Win64");
		let index = controller.Add(preset);
		Test.Assert((index == 1) && (controller.At(1).Name == "Steam"));
		Test.Assert(controller.Add(preset) == 2);
		Test.Assert(controller.At(2).Name == "Steam Copy");
		Test.Assert(controller.Duplicate(1) == 3);
		Test.Assert(controller.At(3).Name == "Steam Copy 2");
		preset.Name.Set("Steam");
		controller.Update(1, preset);
		Test.Assert(controller.At(1).Name == "Steam", "its own name is not taken by itself");
		controller.Update(2, preset);
		Test.Assert(controller.At(2).Name == "Steam Copy", "taken by index 1");
		controller.Remove(3);
		Test.Assert(controller.Count == 3);
		Test.Assert(controller.Save(fs) case .Ok);
		let reloaded = scope ExportPresetsController();
		reloaded.Load(fs);
		Test.Assert((reloaded.Count == 3) && (reloaded.At(2).Name == "Steam Copy"));
	}

	[Test]
	public static void RootsMembershipTogglesIdempotentlyAndRoundTripsThroughXml()
	{
		let dir = Scratch("scratch_export_roots", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let roots = scope ExportRootsSet();
		Test.Assert(roots.IsEmpty);
		let a = Guid.Parse("00000000-0000-0000-0000-00000000000a").Get();
		Test.Assert(roots.SetInstance(a, true) && roots.HasInstance(a));
		Test.Assert(roots.SetInstance(a, true) && (roots.Instances.Count == 1), "idempotent");
		Test.Assert(!roots.ToggleInstance(a) && !roots.HasInstance(a));
		Test.Assert(roots.ToggleInstance(a));
		Test.Assert(roots.SetGroup("levels/hub", true) && roots.HasGroup("levels/hub"));
		Test.Assert(roots.SetGroup("levels/hub", true) && (roots.Groups.Count == 1));
		Test.Assert(!roots.ToggleGroup("levels/hub") && !roots.HasGroup("levels/hub"));
		roots.SetGroup("levels/hub", true);
		let fs = scope NativeFileSystem(dir);
		Test.Assert(ExportRootsFile.Save(fs, roots) case .Ok);
		let loaded = scope ExportRootsSet();
		Test.Assert(ExportRootsFile.Load(fs, loaded) case .Ok);
		Test.Assert(loaded.HasInstance(a) && loaded.HasGroup("levels/hub") && (loaded.Instances.Count == 1));
		Test.Assert(ExportRootsFile.Load(fs, scope ExportRootsSet(), "missing.xml") case .Err(.NotFound));
	}

	/// A file copied for a dist keeps its executable bit, and a file that was not executable
	/// does not become so: a staged player must still start.
	[Test]
	public static void ACopyKeepsWhatWasExecutable()
	{
		let from = Scratch("scratch_filecopy_from", .. scope .());
		let to = Scratch("scratch_filecopy_to", .. scope .());
		defer { RemoveDirectoryRecursive(from); RemoveDirectoryRecursive(to); }
		SaveText(from, "player", "#!player\n");
		FileCopy.MakeExecutable(PathJoin(from, "player", .. scope .()));
		SaveText(from, "libfoo.so", "foo\n");
		Test.Assert(FileCopy.CopyFile(from, "player", to, "Game"));
		Test.Assert(FileCopy.CopyFile(from, "libfoo.so", to, "libfoo.so"));
		Test.Assert(FileExists(PathJoin(to, "Game", .. scope .())) && FileExists(PathJoin(to, "libfoo.so", .. scope .())));
		Test.Assert(!FileCopy.CopyFile(from, "missing", to, "missing"), "nothing to copy");
#if !BF_PLATFORM_WINDOWS
		Test.Assert(access(PathJoin(to, "Game", .. scope .()).CStr(), 1) == 0, "the player is still executable");
		Test.Assert(access(PathJoin(to, "libfoo.so", .. scope .()).CStr(), 1) != 0, "and nothing became executable that was not");
#endif
	}

#if !BF_PLATFORM_WINDOWS
	[CLink]
	private static extern int32 access(char8* path, int32 mode);
#endif
}
