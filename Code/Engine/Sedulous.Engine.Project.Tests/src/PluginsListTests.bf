using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// A part for the status cases.
class StatusPart : PluginPart
{
	private String mId = new .() ~ delete _;

	public this(StringView id) { mId.Set(id); }

	public override StringView PluginId => mId;
	public override PluginPartKind Kind => .Engine;
	public override void Load(PluginContext context) {}
}

/// The project's plugins list: appended, so a manifest without it opens with none; an entry kept
/// as written (its platforms and its settings, whether or not any plugin here reads them) through
/// a save, a reopen and the dist copy; and what became of each entry in a host.
class PluginsListTests
{
	private const String kScratch = "scratch_project_plugins";

	private static void FreshScratch()
	{
		RemoveDirectoryRecursive(kScratch);
		Test.Assert(CreateDirectory(kScratch));
	}

	[Test]
	public static void ThePluginsListIsAppendedAndAnEntryNoPluginHereReadsIsKeptAsWritten()
	{
		FreshScratch();
		let path = scope $"{kScratch}/{ProjectLayout.ManifestFile}";
		{
			let fs = scope NativeFileSystem(kScratch);
			let created = scope ProjectSettings();
			created.Name.Set("P");
			Test.Assert(ProjectManifest.Save(fs, created) case .Ok);
		}
		// Saved before the list: its key stripped from what the save wrote.
		{
			let older = File.ReadAllText(path, .. scope .());
			let start = older.IndexOf("<array name=\"plugins\"");
			Test.Assert(start >= 0, older);
			let close = older.IndexOf("/>", start);
			Test.Assert(close > start);
			older.Remove(start, close + 2 - start);
			Test.Assert(File.WriteAllText(path, older) case .Ok);
		}
		let unknown = "<object name=\"mystery\"><i32 name=\"appId\">480</i32></object>";
		{
			let fs = scope NativeFileSystem(kScratch);
			let settings = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, settings) case .Ok);
			Test.Assert(settings.Plugins.IsEmpty);

			let steam = new EnabledPlugin();
			steam.Id.Set("steam");
			steam.Platforms.Add(new .("Linux64"));
			steam.Platforms.Add(new .("Win64"));
			steam.Settings.AddRange(Span<uint8>((uint8*)unknown.Ptr, unknown.Length));
			settings.Plugins.Add(steam);
			let game = new EnabledPlugin();
			game.Id.Set("game");
			game.Path.Set("Native");
			settings.Plugins.Add(game);
			Test.Assert(ProjectManifest.Save(fs, settings) case .Ok);
		}
		let saved = File.ReadAllText(path, .. scope .());
		Test.Assert(saved.Contains("<i32 name=\"appId\">480</i32>"), saved);
		{
			let fs = scope NativeFileSystem(kScratch);
			let settings = scope ProjectSettings();
			Test.Assert(ProjectManifest.Load(fs, settings) case .Ok);
			Test.Assert(settings.Plugins.Count == 2);
			Test.Assert(settings.FindPlugin("steam") != null);
			Test.Assert(settings.FindPlugin("steam").Platforms.Count == 2);
			Test.Assert(settings.FindPlugin("game").Path == "Native");
			Test.Assert(settings.FindPlugin("absent") == null);
			Test.Assert(ProjectManifest.Save(fs, settings) case .Ok);
			Test.Assert(File.ReadAllText(path, .. scope .()) == saved, "read and written back unchanged");

			let dist = scope ProjectSettings();
			Test.Assert(ProjectManifest.Copy(settings, dist) case .Ok);
			Test.Assert(dist.FindPlugin("steam") != null);
			let copied = dist.FindPlugin("steam").Settings;
			Test.Assert(StringView((char8*)copied.Ptr, copied.Count).Contains("\"appId\">480<"));
		}
		RemoveDirectoryRecursive(kScratch);
	}

	private static String Manifest(StringView id, StringView platform, StringView engineVersion = "0.1")
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set(engineVersion);
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let entry = new PluginPlatform();
		entry.Platform.Set(platform);
		manifest.Platforms.Add(entry);
		return manifest.Write(.. new .());
	}

	private static EnabledPlugin Entry(StringView id, params StringView[] platforms)
	{
		let entry = new EnabledPlugin();
		entry.Id.Set(id);
		for (let platform in platforms)
			entry.Platforms.Add(new .(platform));
		return entry;
	}

	[Test]
	public static void EachEntrysStatusLoadedNotEnabledRefusedOrMissingWithItsReason()
	{
		let here = scope StatusPart("here");
		let webOnly = scope StatusPart("web_only");
		let stale = scope StatusPart("stale");
		let hereXml = Manifest("here", "Linux64");
		defer delete hereXml;
		let webXml = Manifest("web_only", "Web");
		defer delete webXml;
		let staleXml = Manifest("stale", "Linux64", "0.0");
		defer delete staleXml;

		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, "0.1.0", "Linux64");
		Test.Assert(host.AddLinked(hereXml, scope PluginPart[](here)) case .Ok);
		Test.Assert(host.AddLinked(webXml, scope PluginPart[](webOnly)) case .Ok);
		Test.Assert(host.AddLinked(staleXml, scope PluginPart[](stale)) case .Ok);
		let entries = scope List<EnabledPlugin>();
		defer { ClearAndDeleteItems!(entries); }
		entries.Add(Entry("here", "Linux64", "Win64"));
		entries.Add(Entry("web_only"));
		entries.Add(Entry("stale"));
		entries.Add(Entry("absent"));
		host.Load((Span<EnabledPlugin>)entries, scope .());

		let loaded = scope PluginStatus();
		PluginStatus.Of(entries[0], host, loaded);
		Test.Assert(loaded.State == .Loaded);
		Test.Assert(loaded.Reason.IsEmpty);
		Test.Assert((loaded.UnsupportedPlatforms.Count == 1) && (loaded.UnsupportedPlatforms[0] == "Win64"));

		let notEnabled = scope PluginStatus();
		PluginStatus.Of(entries[1], host, notEnabled);
		Test.Assert(notEnabled.State == .NotEnabled);
		Test.Assert(notEnabled.Reason.Contains("is not enabled on Linux64"));

		let refused = scope PluginStatus();
		PluginStatus.Of(entries[2], host, refused);
		Test.Assert(refused.State == .Refused);
		Test.Assert(refused.Reason.Contains("needs engine 0.0"));

		let missing = scope PluginStatus();
		PluginStatus.Of(entries[3], host, missing);
		Test.Assert(missing.State == .Missing);
		Test.Assert(missing.Reason.Contains("is not in this build"));
		Test.Assert(PluginState.Missing.Name == "missing");

		let noHost = scope PluginStatus();
		PluginStatus.Of(entries[0], null, noHost);
		Test.Assert(noHost.State == .Missing);
		Test.Assert(noHost.Reason.Contains("this host loads no plugins"));
		host.Unload();
	}
}
