using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;
using Sedulous.Xml.Serialization;

namespace Sedulous.Runtime.Tests;

/// A plugin's settings type: what its part reads from the project's entry.
[Serializable(1)]
class ProbeConfig
{
	public int32 Volume = 3;
	public String Name = new .("default") ~ delete _;
}

/// Another type's settings, whose payload a ProbeConfig does not read.
[Serializable(1)]
class OtherConfig
{
	public bool Flag;
}

/// The configured plugin's part: reads its settings when it loads.
class ConfiguredPart : PluginPart
{
	public static int32 VolumeAtLoad = 0;
	public static bool OtherTypeRefused = false;

	public override StringView PluginId => "configured";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let config = context.Settings<ProbeConfig>();
		VolumeAtLoad = (config != null) ? config.Volume : -1;
		OtherTypeRefused = context.Settings<OtherConfig>() == null;
	}
}

/// A part for the platform cases.
class PlatformPart : PluginPart
{
	private String mId = new .() ~ delete _;

	public this(StringView id) { mId.Set(id); }

	public override StringView PluginId => mId;
	public override PluginPartKind Kind => .Engine;
	public override void Load(PluginContext context) {}
}

/// A document holding entries, as the project's manifest does.
[Serializable]
class EntryList
{
	public List<EnabledPlugin> Plugins = new .() ~ DeleteContainerAndItems!(_);
}

/// A project's plugin entries: where each is enabled (absent elsewhere, refused where its plugin
/// cannot run), its settings read by its part and written back by an editor, and kept verbatim
/// through XML and binary copies by whoever does not read them.
class EnabledPluginTests
{
	private static String Manifest(StringView id, Span<StringView> platforms)
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set(id);
		manifest.Name.Set(id);
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		for (let platform in platforms)
		{
			let entry = new PluginPlatform();
			entry.Platform.Set(platform);
			manifest.Platforms.Add(entry);
		}
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

	/// What a player on `platform` enables of `entries` (TAKEN), over anywhere (every platform)
	/// and desktop (Linux64 and Win64).
	private static void LoadOn(StringView platform, PluginLoadReport outReport, params EnabledPlugin[] entries)
	{
		let anywhere = scope PlatformPart("anywhere");
		let desktop = scope PlatformPart("desktop");
		let anywhereXml = Manifest("anywhere", scope StringView[]("Linux64", "Win64", "Web"));
		defer delete anywhereXml;
		let desktopXml = Manifest("desktop", scope StringView[]("Linux64", "Win64"));
		defer delete desktopXml;
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Player, "0.1.0", platform);
		Test.Assert(host.Platform == platform);
		Test.Assert(host.AddLinked(anywhereXml, scope PluginPart[](anywhere)) case .Ok);
		Test.Assert(host.AddLinked(desktopXml, scope PluginPart[](desktop)) case .Ok);
		host.Load(entries, outReport);
		host.Unload();
		for (let entry in entries)
			delete entry;
	}

	private static bool Same(List<String> lines, params StringView[] expected)
	{
		if (lines.Count != expected.Count)
			return false;
		for (int i < lines.Count)
		{
			if (lines[i] != expected[i])
				return false;
		}
		return true;
	}

	[Test]
	public static void AnEntryLoadsWhereItIsEnabledIsAbsentElsewhereAndIsRefusedWhereItsPluginCannotRun()
	{
		// Naming no platforms is every platform the manifest supports.
		{
			let web = scope PluginLoadReport();
			LoadOn("Web", web, Entry("anywhere"), Entry("desktop"));
			Test.Assert(Same(web.Loaded, "anywhere"));
			Test.Assert(Same(web.NotEnabled, "desktop"));
			Test.Assert(web.Refused.IsEmpty);
			let linux = scope PluginLoadReport();
			LoadOn("Linux64", linux, Entry("anywhere"), Entry("desktop"));
			Test.Assert(Same(linux.Loaded, "anywhere", "desktop"));
		}
		// Naming platforms enables it on those alone.
		{
			let web = scope PluginLoadReport();
			LoadOn("Web", web, Entry("anywhere", "Win64", "Web"));
			Test.Assert(Same(web.Loaded, "anywhere"));
			let linux = scope PluginLoadReport();
			LoadOn("Linux64", linux, Entry("anywhere", "Win64", "Web"));
			Test.Assert(linux.Loaded.IsEmpty);
			Test.Assert(Same(linux.NotEnabled, "anywhere"));
		}
		// Naming a platform the manifest does not support is refused there, and reported.
		{
			let web = scope PluginLoadReport();
			LoadOn("Web", web, Entry("desktop", "Linux64", "Web"));
			let refusal = web.FindRefusal("desktop");
			Test.Assert((refusal != null) && refusal.Reason.Contains("enabled on Web, which it does not support"));
			let linux = scope PluginLoadReport();
			LoadOn("Linux64", linux, Entry("desktop", "Linux64", "Web"));
			Test.Assert(Same(linux.Loaded, "desktop"));

			let manifest = scope PluginManifest();
			let linuxOnly = new PluginPlatform();
			linuxOnly.Platform.Set("Linux64");
			manifest.Platforms.Add(linuxOnly);
			let entry = Entry("desktop", "Linux64", "Web");
			defer delete entry;
			Test.Assert(entry.EnablementOn(manifest, "Linux64") == .Enabled);
			Test.Assert(entry.EnablementOn(manifest, "Web") == .Unsupported);
			Test.Assert(entry.EnablementOn(manifest, "Win64") == .NotEnabled);
			let unsupported = scope List<String>();
			defer { ClearAndDeleteItems!(unsupported); }
			entry.UnsupportedPlatforms(manifest, unsupported);
			Test.Assert(Same(unsupported, "Web"));
		}
	}

	/// The configured plugin, compiled in, enabled by `entry` (TAKEN) on a player.
	private class ConfiguredBed
	{
		public SubsystemManager Subsystems = new .() ~ delete _;
		public ConfiguredPart Part = new .() ~ delete _;
		public PluginHost Host ~ delete _;
		public EnabledPlugin Entry ~ delete _;

		public this(EnabledPlugin entry)
		{
			Entry = entry;
			Host = new .(Subsystems, .Player, "0.1.0", "Linux64");
			let xml = Manifest("configured", scope StringView[]("Linux64"));
			defer delete xml;
			Test.Assert(Host.AddLinked(xml, scope PluginPart[](Part)) case .Ok);
			let report = scope PluginLoadReport();
			Host.Load(scope EnabledPlugin[](Entry), report);
			Test.Assert(report.Loaded.Count == 1);
		}
	}

	private static void ConfigXml(int32 volume, StringView name, List<uint8> outSettings)
	{
		let config = scope ProbeConfig();
		config.Volume = volume;
		config.Name.Set(name);
		Test.Assert(EnabledPlugin.WriteSettings(config, outSettings) case .Ok);
	}

	[Test]
	public static void APartReadsItsSettingsFromTheProjectsEntryAndAnEditorWritesThemBack()
	{
		let entry = Entry("configured");
		ConfigXml(7, "seven", entry.Settings);
		let bed = scope ConfiguredBed(entry);
		let host = bed.Host;
		Test.Assert(ConfiguredPart.VolumeAtLoad == 7);
		Test.Assert(ConfiguredPart.OtherTypeRefused, "one settings type per plugin");
		Test.Assert(host.Report.Loaded.Count == 1, "kept for whoever reports the project's plugins");
		Test.Assert((host.Manifest("configured") != null) && (host.Manifest("configured").Id == "configured"));
		Test.Assert(host.Manifest("absent") == null);
		Test.Assert(host.SettingsRead("configured"));

		// The editor's path: change the live object, write it into the entry, and it reads back.
		let live = host.Settings("configured") as ProbeConfig;
		Test.Assert(live != null);
		Test.Assert(live.Name == "seven");
		live.Volume = 9;
		Test.Assert(EnabledPlugin.WriteSettings(live, entry.Settings) case .Ok);
		let reread = scope ProbeConfig();
		Test.Assert(EnabledPlugin.ReadSettings((Span<uint8>)entry.Settings, reread) case .Ok);
		Test.Assert(reread.Volume == 9);
		Test.Assert(reread.Name == "seven");
		host.Unload();
		Test.Assert(host.Report.Loaded.IsEmpty);
		Test.Assert(host.Settings("configured") == null);
	}

	[Test]
	public static void AnEntryWithNoSettingsGivesTheDefaults()
	{
		ConfiguredPart.VolumeAtLoad = 0;
		let bed = scope ConfiguredBed(Entry("configured"));
		Test.Assert(ConfiguredPart.VolumeAtLoad == 3);
		Test.Assert(bed.Host.SettingsRead("configured"));
		bed.Host.Unload();
	}

	[Test]
	public static void SettingsThatDoNotReadAsTheTypeGiveTheDefaultsMarkedUnread()
	{
		let entry = Entry("configured");
		let other = scope OtherConfig();
		other.Flag = true;
		Test.Assert(EnabledPlugin.WriteSettings(other, entry.Settings) case .Ok);
		let bed = scope ConfiguredBed(entry);
		Test.Assert(ConfiguredPart.VolumeAtLoad == 3);
		Test.Assert(!bed.Host.SettingsRead("configured"));
		let defaults = bed.Host.Settings("configured") as ProbeConfig;
		Test.Assert((defaults != null) && (defaults.Name == "default"), "the defaults, not what the reader left");
		bed.Host.Unload();

		let subsystems = scope SubsystemManager();
		let none = scope PluginHost(subsystems, .Player, "0.1.0");
		Test.Assert(none.Settings("configured") == null, "a plugin not enabled has no settings object");
	}

	private static void WriteXml(EntryList list, String outXml)
	{
		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(buffer, .Write);
		defer delete context;
		((ISerializable)list).Serialize(context.Serializer);
		Test.Assert(context.Serializer.Status case .Ok);
		context.Flush(buffer);
		outXml.Append(StringView((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length));
	}

	private static void ReadXml(StringView xml, EntryList list)
	{
		let buffer = scope MemoryStream();
		buffer.Write(.((uint8*)xml.Ptr, xml.Length));
		buffer.Seek(0, .Begin);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let context = factory(buffer, .Read);
		defer delete context;
		((ISerializable)list).Serialize(context.Serializer);
		Test.Assert(context.Serializer.Status case .Ok);
	}

	[Test]
	public static void AnEntrysSettingsAreKeptVerbatimReadByNobodyThroughXmlAndBinaryCopies()
	{
		let list = scope EntryList();
		let steam = Entry("steam", "Linux64", "Win64");
		let unknown = "<object name=\"mystery\"><i32 name=\"appId\">480</i32></object>";
		steam.Settings.AddRange(Span<uint8>((uint8*)unknown.Ptr, unknown.Length));
		list.Plugins.Add(steam);
		let local = Entry("paperkid");
		local.Path.Set("Native");
		list.Plugins.Add(local);
		let first = WriteXml(list, .. scope .());
		Test.Assert(first.Contains("480"), first);

		let read = scope EntryList();
		ReadXml(first, read);
		Test.Assert(read.Plugins.Count == 2);
		Test.Assert(read.Plugins[0].Id == "steam");
		Test.Assert(read.Plugins[0].Platforms.Count == 2);
		Test.Assert(read.Plugins[1].Path == "Native");
		Test.Assert(read.Plugins[1].Settings.IsEmpty);
		Test.Assert(WriteXml(read, .. scope .()) == first);

		// Through the binary serializer, as a copy of the manifest goes.
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			((ISerializable)read).Serialize(writer);
			Test.Assert(writer.Status case .Ok);
		}
		buffer.Seek(0, .Begin);
		let copied = scope EntryList();
		let reader = scope BinarySerializer(buffer, .Read);
		((ISerializable)copied).Serialize(reader);
		Test.Assert(reader.Status case .Ok);
		Test.Assert(WriteXml(copied, .. scope .()) == first);
	}
}
