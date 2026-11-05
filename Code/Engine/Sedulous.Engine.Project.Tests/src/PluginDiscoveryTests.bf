using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// A linked part carrying its plugin's manifest.
class DiscoveredPart : PluginPart
{
	private String mId = new .() ~ delete _;
	private String mManifest = new .() ~ delete _;

	public this(StringView id, StringView manifest)
	{
		mId.Set(id);
		mManifest.Set(manifest);
	}

	public override StringView PluginId => mId;
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => mManifest;
	public override void Load(PluginContext context) {}
}

/// What a project could enable: its packages no entry names, by folder, each with why it is not
/// offered when it is not, then the linked plugins no entry enables.
class PluginDiscoveryTests
{
	private const String cRoot = "scratch_plugin_discovery";

	private static String Manifest(StringView id, StringView engine = "0.1")
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Name.Set(scope $"The {id}");
		manifest.Version.Set("1.0.0");
		manifest.EngineVersion.Set(engine);
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set("Linux64");
		manifest.Platforms.Add(platform);
		return manifest.Write(.. new .());
	}

	private static void Package(StringView folder, StringView xml)
	{
		let dir = scope $"{cRoot}/Plugins/{folder}";
		CreateDirectory(dir);
		Test.Assert(WriteFile(PathJoin(dir, "Plugin.xml", .. scope .()), .((uint8*)xml.Ptr, xml.Length)) case .Ok);
	}

	[Test]
	public static void APackageNoEntryNamesAndALinkedPluginNoEntryEnablesAreAvailable()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		CreateDirectory(scope $"{cRoot}/Plugins");
		defer RemoveDirectoryRecursive(cRoot);
		let fresh = Manifest("fresh");
		defer delete fresh;
		Package("Fresh", fresh);
		Package("Broken", "<root>not a manifest");
		let old = Manifest("old", "0.0");
		defer delete old;
		Package("Old", old);
		let taken = Manifest("taken");
		defer delete taken;
		Package("Taken", taken);
		let named = Manifest("named");
		defer delete named;
		Package("Named", named);
		let linkedTwice = Manifest("linked");
		defer delete linkedTwice;
		Package("Linked", linkedTwice);
		CreateDirectory(scope $"{cRoot}/Plugins/NoPackage");

		let settings = scope ProjectSettings();
		let takenEntry = new EnabledPlugin();
		takenEntry.Id.Set("taken");
		settings.Plugins.Add(takenEntry);
		let namedEntry = new EnabledPlugin();
		namedEntry.Id.Set("named");
		namedEntry.Path.Set("Plugins/Named");
		settings.Plugins.Add(namedEntry);

		let linkedManifest = Manifest("linked");
		defer delete linkedManifest;
		let offeredManifest = Manifest("offered");
		defer delete offeredManifest;
		let parts = scope List<PluginPart>();
		defer { ClearAndDeleteItems!(parts); }
		parts.Add(new DiscoveredPart("offered", offeredManifest));
		parts.Add(new DiscoveredPart("linked", linkedManifest));
		parts.Add(new DiscoveredPart("taken", taken));

		let found = scope List<AvailablePlugin>();
		defer { ClearAndDeleteItems!(found); }
		PluginDiscovery.Discover(cRoot, settings, (Span<PluginPart>)parts, found);
		// Broken, Fresh, Linked, Old, Taken by folder; then the linked plugins no entry enables.
		Test.Assert(found.Count == 7, scope $"{found.Count} found");
		Test.Assert((found[0].Path == "Plugins/Broken") && found[0].Problem.Contains("does not read"), found[0].Problem);
		Test.Assert((found[1].Id == "fresh") && found[1].Problem.IsEmpty && (found[1].Name == "The fresh") && (found[1].Version == "1.0.0"));
		Test.Assert((found[1].Parts.Count == 1) && (found[1].Parts[0] == "Engine") && (found[1].Platforms[0] == "Linux64"));
		Test.Assert(found[2].Problem.Contains("is linked into this build"), found[2].Problem);
		Test.Assert(!found[3].Problem.IsEmpty, "built for an older engine");
		Test.Assert(found[4].Problem.Contains("already enabled, as the engine's"), found[4].Problem);
		Test.Assert((found[5].Id == "linked") && found[5].Path.IsEmpty && found[5].Problem.IsEmpty);
		Test.Assert((found[6].Id == "offered") && found[6].Path.IsEmpty);
	}
}
