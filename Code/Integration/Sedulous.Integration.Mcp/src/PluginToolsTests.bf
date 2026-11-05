using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The fixture plugin's settings, labelled as the project's settings are.
[Serializable(1)]
class MeterSettings
{
	[Setting("Volume"), Range(0, 10, 1)]
	public uint32 Volume = 3;
	[Setting("Loud")]
	public bool Loud = false;
	[Setting("Greeting")]
	public String Greeting = new .("hello") ~ delete _;
}

/// The meter plugin's part: it asks for its settings, and the test reads them through it.
class MeterPart : PluginPart
{
	public static MeterSettings Settings;

	public override StringView PluginId => "meter";
	public override PluginPartKind Kind => .Engine;
	public override void Load(PluginContext context) { Settings = context.Settings<MeterSettings>(); }
	public override void Unload(PluginContext context) { Settings = null; }
}

/// The project's plugins through the tools. A plugin compiled into this test, with a settings type
/// labelled as the project's settings are, is enabled from the project's entries by a plugin host;
/// plugin_list reports every entry against it and plugin_settings_set changes the enabled plugin's
/// settings, while an entry whose plugin is missing keeps its settings exactly as written; and
/// plugin_enable and plugin_disable change the list.
static class PluginToolsTests
{
	/// The meter's manifest: supported on this platform alone.
	private static String MeterManifest()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("meter");
		manifest.Name.Set("Meter");
		manifest.Version.Set("1.2.0");
		manifest.EngineVersion.Set(EngineVersion.String);
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		return manifest.Write(.. new .());
	}

	private static JsonValue SettingsArgs(StringView id, JsonValue settings)
	{
		let arguments = With(Obj(), "id", id);
		arguments.Set("settings", settings);
		return arguments;
	}

	private static StringView SettingsText(EnabledPlugin entry) => StringView((char8*)entry.Settings.Ptr, entry.Settings.Count);

	[Test]
	public static void AnAgentListsTheProjectsPluginsAndSetsAnEnabledPluginsSettings()
	{
		let dir = Scratch("mcp_plugins", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		PluginTools.Register(server, session);
		int changed = 0;
		session.OnSettingsChanged = new [&changed] () => { changed++; };
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Plugins"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// The project enables the meter (here and on the web, which its manifest lacks) and a plugin
		// this build does not have, whose settings nothing here can read.
		let settings = session.Project.Settings;
		let meter = new EnabledPlugin();
		meter.Id.Set("meter");
		meter.Platforms.Add(new .(PluginHost.HostPlatform));
		meter.Platforms.Add(new .("Web"));
		settings.Plugins.Add(meter);
		let steam = new EnabledPlugin();
		steam.Id.Set("steam");
		let unknown = "<object name=\"mystery\"><i32 name=\"appId\">480</i32></object>";
		steam.Settings.AddRange(Span<uint8>((uint8*)unknown.Ptr, unknown.Length));
		settings.Plugins.Add(steam);
		Test.Assert(session.Project.SaveSettings() case .Ok);

		// The host's own plugins (project_open enabled the ones it links, none here): every entry is
		// missing, and nothing can be set.
		Test.Assert(session.Plugins != null);
		{
			let listed = CallOk(server, "plugin_list", Obj());
			defer delete listed;
			Test.Assert(listed.Get("plugins").At(0).Get("state").AsString() == "missing");
			let refused = scope String();
			CallErr(server, "plugin_settings_set", SettingsArgs("meter", Obj()), refused);
			Test.Assert(refused.Contains("not in this build; its settings are kept as written"), refused);
		}
		// With no plugin host at all, the same, said so.
		session.Plugins = null;
		{
			let refused = scope String();
			CallErr(server, "plugin_settings_set", SettingsArgs("meter", Obj()), refused);
			Test.Assert(refused.Contains("this host loads no plugins; its settings are kept as written"), refused);
		}

		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Mcp, EngineVersion.String);
		let part = scope MeterPart();
		let manifestXml = MeterManifest();
		defer delete manifestXml;
		Test.Assert(host.AddLinked(manifestXml, scope PluginPart[](part)) case .Ok);
		host.Load((Span<EnabledPlugin>)settings.Plugins, scope .());
		Test.Assert(MeterPart.Settings != null);
		session.Plugins = host;

		{
			let listed = CallOk(server, "plugin_list", Obj());
			defer delete listed;
			Test.Assert(listed.Get("platform").AsString() == PluginHost.HostPlatform);
			let plugins = listed.Get("plugins");
			Test.Assert(plugins.Count == 2);
			let first = plugins.At(0);
			Test.Assert(first.Get("id").AsString() == "meter");
			Test.Assert(first.Get("state").AsString() == "loaded");
			Test.Assert(first.Get("name").AsString() == "Meter");
			Test.Assert(first.Get("version").AsString() == "1.2.0");
			Test.Assert((first.Get("unsupportedPlatforms").Count == 1) && (first.Get("unsupportedPlatforms").At(0).AsString() == "Web"));
			Test.Assert(first.Get("settings").Get("volume").AsNumber() == 3.0);
			Test.Assert(first.Get("settings").Get("greeting").AsString() == "hello");
			Test.Assert(first.Get("settingsEditable").AsBool());
			let second = plugins.At(1);
			Test.Assert(second.Get("state").AsString() == "missing");
			Test.Assert(second.Get("reason").AsString().Contains("not in this build"));
			Test.Assert(second.Get("settings").IsNull);
			Test.Assert(!second.Get("settingsEditable").AsBool());
		}

		// Refusals change nothing: a setting it does not have, a value out of range, a missing
		// plugin, an id the project does not enable.
		{
			let refused = scope String();
			CallErr(server, "plugin_settings_set", SettingsArgs("meter", With(Obj(), "volumme", 5)), refused);
			Test.Assert(refused.Contains("has no setting 'volumme' (its settings: volume, loud, greeting)"), refused);
			CallErr(server, "plugin_settings_set", SettingsArgs("meter", With(With(Obj(), "volume", 11), "greeting", "never")), refused..Clear());
			Test.Assert(MeterPart.Settings.Greeting == "hello");
			CallErr(server, "plugin_settings_set", SettingsArgs("steam", Obj()), refused..Clear());
			Test.Assert(refused.Contains("not in this build; its settings are kept as written"), refused);
			CallErr(server, "plugin_settings_set", SettingsArgs("absent", Obj()), refused..Clear());
			Test.Assert(changed == 0);
		}

		// A change reaches the plugin at once, the project's entry and the saved manifest.
		{
			let change = With(Obj(), "volume", 7);
			change.Set("loud", JsonValue.MakeBool(true));
			let set = CallOk(server, "plugin_settings_set", SettingsArgs("meter", change));
			defer delete set;
			Test.Assert(changed == 1);
			Test.Assert(set.Get("settings").Get("volume").AsNumber() == 7.0);
			Test.Assert(MeterPart.Settings.Volume == 7);
			Test.Assert(MeterPart.Settings.Loud);
			Test.Assert(MeterPart.Settings.Greeting == "hello", "not given: unchanged");
		}

		host.Unload();
		session.Plugins = null;
		session.Project = null;
		DeleteAndNullify!(owner.Project);
		let reopened = EditorProject.Open(dir);
		Test.Assert(reopened != null);
		defer delete reopened;
		let saved = reopened.Settings.FindPlugin("meter");
		Test.Assert(saved != null);
		let reread = scope MeterSettings();
		Test.Assert(EnabledPlugin.ReadSettings((Span<uint8>)saved.Settings, reread) case .Ok);
		Test.Assert(reread.Volume == 7);
		Test.Assert(reread.Loud);
		let kept = reopened.Settings.FindPlugin("steam");
		Test.Assert(kept != null);
		Test.Assert(SettingsText(kept).Contains("<i32 name=\"appId\">480</i32>"), "kept, though unread");
	}

	private static JsonValue EnableArgs(StringView id, params StringView[] platforms)
	{
		let arguments = With(Obj(), "id", id);
		let list = JsonValue.MakeArray();
		for (let platform in platforms)
			list.Add(JsonValue.MakeString(platform));
		arguments.Set("platforms", list);
		return arguments;
	}

	[Test]
	public static void AnAgentEnablesAndDisablesPluginsInTheProject()
	{
		let dir = Scratch("mcp_plugins_enable", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		PluginTools.Register(server, session);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Enable"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// The host knows the meter (this platform only), so its platforms are checked against it.
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Mcp, EngineVersion.String);
		let part = scope MeterPart();
		let manifestXml = MeterManifest();
		defer delete manifestXml;
		Test.Assert(host.AddLinked(manifestXml, scope PluginPart[](part)) case .Ok);
		session.Plugins = host;

		// Refusals leave the list as it was.
		let refused = scope String();
		let elsewhere = (PluginHost.HostPlatform == "Web") ? "Linux64" : "Web";
		CallErr(server, "plugin_enable", EnableArgs("meter", elsewhere), refused);
		Test.Assert(refused.Contains(scope $"plugin 'meter' does not support {elsewhere} (it supports: "), refused);
		CallErr(server, "plugin_enable", EnableArgs("Steam!"), refused..Clear());
		CallErr(server, "plugin_enable", With(With(Obj(), "id", "game"), "path", "Nowhere"), refused..Clear());
		Test.Assert(refused.Contains("'Nowhere' holds no plugin manifest"), refused);
		Test.Assert(session.Project.Settings.Plugins.IsEmpty);

		// The meter here, and a plugin this build does not know, which only the project can hold.
		{
			let enabled = CallOk(server, "plugin_enable", EnableArgs("meter", PluginHost.HostPlatform));
			defer delete enabled;
			Test.Assert(enabled.Get("plugins").Count == 1);
			Test.Assert(enabled.Get("plugins").At(0).Get("platforms").At(0).AsString() == PluginHost.HostPlatform);
		}
		{
			let enabled = CallOk(server, "plugin_enable", EnableArgs("steam", "Linux64", "Win64"));
			defer delete enabled;
			Test.Assert(enabled.Get("plugins").At(1).Get("state").AsString() == "missing");
		}

		// Enabling again changes its platforms and keeps its settings.
		var entry = session.Project.Settings.FindPlugin("steam");
		Test.Assert(entry != null);
		let kept = "<i32 name=\"appId\">480</i32>";
		entry.Settings.AddRange(Span<uint8>((uint8*)kept.Ptr, kept.Length));
		delete CallOk(server, "plugin_enable", EnableArgs("steam"));
		entry = session.Project.Settings.FindPlugin("steam");
		Test.Assert(entry != null);
		Test.Assert(entry.Platforms.IsEmpty);
		Test.Assert(SettingsText(entry) == kept);

		// Disabling removes the entry; one the project does not enable is refused.
		{
			let gone = CallOk(server, "plugin_disable", With(Obj(), "id", "steam"));
			defer delete gone;
			Test.Assert(gone.Get("plugins").Count == 1);
		}
		CallErr(server, "plugin_disable", With(Obj(), "id", "steam"), refused..Clear());

		session.Plugins = null;
		session.Project = null;
		DeleteAndNullify!(owner.Project);
		let reopened = EditorProject.Open(dir);
		Test.Assert(reopened != null);
		defer delete reopened;
		Test.Assert(reopened.Settings.Plugins.Count == 1);
		Test.Assert(reopened.Settings.Plugins[0].Id == "meter");
	}
}
