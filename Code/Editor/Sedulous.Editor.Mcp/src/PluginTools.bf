using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// The open project's plugins over MCP: plugin_list reports each entry of the project's list as
/// the process's plugin host left it (loaded, not enabled here, refused, missing) with its
/// settings, plugin_enable adds an entry or changes its path and platforms, plugin_disable removes
/// one, plugin_settings_set changes a loaded plugin's settings, and plugin_scaffold makes the
/// game's own package or adds parts to it (what the editor's Add Native Code does). A plugin's
/// settings are its own
/// reflected type, labelled as the project's settings are ([Setting]), so both read and check them
/// through ReflectedFields. An entry whose plugin is not loaded keeps its settings as written:
/// nothing here can read them, so nothing here changes them.
static class PluginTools
{
	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterTool("plugin_list",
			"The plugins the open project enables, in its order: each entry's id, path (a project-local package; empty for the engine's), platforms (empty is every platform its manifest supports), and its state in this host on `platform`: loaded, notEnabled (not enabled on this platform), refused or missing, with the reason when it is not loaded. unsupportedPlatforms lists platforms the entry names that its manifest does not support. A loaded plugin with settings reports them (`settings`, as project_info reports the project's), and settingsEditable says whether plugin_settings_set may change them; any other entry's settings are kept as written. `available` lists what the project could enable: each package in its Plugins folder no entry names and each plugin this host links that no entry enables (path empty), with name, version, parts and platforms; `offered` false with a `problem` when it cannot be enabled (its manifest does not read or suit this engine, or its id is taken). Enable one with plugin_enable (its id, and its path for a package).",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				if (!session.IsOpen)
				{
					outError.Append(McpTools.cNoProject);
					return false;
				}
				ListJson(session, outResult);
				return true;
			});

		server.RegisterTool("plugin_enable",
			"Enable a plugin in the open project, or change an enabled one's `path` or `platforms`; its settings are kept. `id` is the plugin's manifest id. `path` locates a project-local package (a folder with its Plugin.xml, relative to the project; \"\" for the engine's). `platforms` lists the platforms it is enabled on (Linux64, Win64, Web), [] for every one its manifest supports. Refused when the id is not a plugin id, when the package at `path` is not this plugin's, or when a platform named is one its manifest does not support. A host enables the project's plugins when it opens the project, so the change takes effect there. Returns the list as plugin_list does.",
			scope SchemaBuilder()
				.Str("id", "the plugin's manifest id", true)
				.Str("path", "a project-local package, relative to the project (\"\" for the engine's)")
				.Arr("platforms", "string", "the platforms it is enabled on; [] for all it supports")
				.Build(),
			.Adjusts,
			new (arguments, outResult, outError) => Enable(session, arguments, outResult, outError));

		server.RegisterTool("plugin_disable",
			"Disable a plugin in the open project: its entry leaves the list, and its settings with it (plugin_list shows them first). The plugin stays enabled in a host until it next opens the project. Returns the list as plugin_list does.",
			scope SchemaBuilder().Str("id", "the plugin's id, as plugin_list names it", true).Build(),
			.Adjusts,
			new (arguments, outResult, outError) =>
			{
				if (!session.IsOpen)
				{
					outError.Append(McpTools.cNoProject);
					return false;
				}
				let id = arguments.Get("id").AsString();
				let plugins = session.Project.Settings.Plugins;
				for (int i < plugins.Count)
				{
					if (plugins[i].Id != id)
						continue;
					delete plugins[i];
					plugins.RemoveAt(i);
					return SaveList(session, outResult, outError);
				}
				outError.AppendF("the project enables no plugin '{}' (plugin_list names them)", id);
				return false;
			});

		server.RegisterTool("plugin_settings_set",
			"Change a loaded plugin's settings: `id` names it, `settings` holds the settings to change by name (only what is given changes), each taking what its kind takes in project_settings_set. Checked in full before anything changes, then written into the project's entry and saved to the manifest; the plugin sees the new values at once. Refused for a plugin that is not loaded here, has no settings, or whose saved settings did not read (those are kept as written). Returns the entry as plugin_list reports it.",
			scope SchemaBuilder()
				.Str("id", "the plugin's id, as plugin_list names it", true)
				.Map("settings", "the settings to change, by name", true)
				.Build(),
			.Adjusts,
			new (arguments, outResult, outError) => SetSettings(session, arguments, outResult, outError));

		server.RegisterTool("plugin_scaffold",
			"Scaffold the game's native code, as the editor's Add Native Code does: the game's own package in Code/, the project's Beef workspace (<Game> named from the project's name), with the `parts` asked for (Engine, Pipeline, Tooling, Editor; default Engine): the Engine part Code/<Game>/, any other Code/<Game>.<Kind>/, each with its BeefProj.toml and a source whose Load finds the service its host hands that kind; the Engine part depends on the game tiers (Scene, Engine.Composition, Engine.Gameplay) and its Load registers a starter behaviour, Rotator (src/Rotator.bf). A package already there gains the parts it lacks. Lists them in Code/Plugin.xml and Code/BeefSpace.toml (keeping the user's lines), writes Code/.gitignore when there is none, enables the package in the project (path `Code`) and saves. Refused when every part asked for is there, the project already enables a plugin of the game's id elsewhere, or a part's folder is there already; it never overwrites code. The editor's Project > Build Project builds it into the project's own editor and player. Returns the package's id, path and parts.",
			scope SchemaBuilder().Arr("parts", "string", "the parts to make: Engine, Pipeline, Tooling, Editor (default Engine)").Build(),
			.Adjusts,
			new (arguments, outResult, outError) => Scaffold(session, arguments, outResult, outError));
	}

	/// plugin_scaffold: the game's package, or the parts it lacks, as Add Native Code makes them.
	private static bool Scaffold(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let parts = scope List<PluginPartKind>();
		if (let given = arguments.Get("parts"))
		{
			for (int i < given.Count)
			{
				let name = given.At(i);
				PluginPartKind kind = .Engine;
				bool known = false;
				if (name.IsString)
				{
					if (PluginPartKind.Parse(name.AsString()) case .Ok(let parsed))
					{
						kind = parsed;
						known = true;
					}
				}
				if (!known)
				{
					outError.Append("`parts` takes part kinds: Engine, Pipeline, Tooling or Editor");
					return false;
				}
				if (!parts.Contains(kind))
					parts.Add(kind);
			}
		}
		if (parts.IsEmpty)
			parts.Add(.Engine);
		if (GamePackage.Scaffold(session.Project, (Span<PluginPartKind>)parts) case .Err(let err))
		{
			if (err == .AlreadyExists)
				outError.Append("every part asked for is there already, or the game's id is enabled elsewhere or a part's folder is in Code/ already; nothing was touched");
			else
				outError.Append("the scaffold failed (log_read says why)");
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		let package = scope GamePackageInfo();
		GamePackage.Find(session.Project, package);
		outResult.Set("id", JsonValue.MakeString(package.Id));
		outResult.Set("path", JsonValue.MakeString(package.Path));
		let kinds = JsonValue.MakeArray();
		for (let kind in package.Parts)
			kinds.Add(JsonValue.MakeString(kind.ToString(.. scope .())));
		outResult.Set("parts", kinds);
		return true;
	}

	/// The settings object an enabled plugin's parts read, or null.
	private static Object LoadedSettings(ProjectSession session, StringView id) =>
		(session.Plugins != null) ? session.Plugins.Settings(id) : null;

	/// One entry as plugin_list reports it, into `outEntry`.
	private static void EntryJson(ProjectSession session, EnabledPlugin entry, JsonValue outEntry)
	{
		let status = scope PluginStatus();
		PluginStatus.Of(entry, session.Plugins, status);
		outEntry.Set("id", JsonValue.MakeString(entry.Id));
		outEntry.Set("path", JsonValue.MakeString(entry.Path));
		let platforms = JsonValue.MakeArray();
		for (let platform in entry.Platforms)
			platforms.Add(JsonValue.MakeString(platform));
		outEntry.Set("platforms", platforms);
		outEntry.Set("state", JsonValue.MakeString(status.State.Name));
		if (!status.Reason.IsEmpty)
			outEntry.Set("reason", JsonValue.MakeString(status.Reason));
		let unsupported = JsonValue.MakeArray();
		for (let platform in status.UnsupportedPlatforms)
			unsupported.Add(JsonValue.MakeString(platform));
		outEntry.Set("unsupportedPlatforms", unsupported);
		if (let manifest = (session.Plugins != null) ? session.Plugins.Manifest(entry.Id) : null)
		{
			outEntry.Set("name", JsonValue.MakeString(manifest.Name));
			outEntry.Set("version", JsonValue.MakeString(manifest.Version));
		}
		let settings = LoadedSettings(session, entry.Id);
		if (settings != null)
		{
			let fields = scope List<FieldInfo>();
			SettingFields.Of(settings.GetType(), fields);
			outEntry.Set("settings", ReflectedFields.ToJson(settings, fields, session.Project.SourceDb));
		}
		else
			outEntry.Set("settings", JsonValue.MakeNull());
		outEntry.Set("settingsEditable", JsonValue.MakeBool((settings != null) && session.Plugins.SettingsRead(entry.Id)));
	}

	/// The list, into `outResult`.
	private static void ListJson(ProjectSession session, JsonValue outResult)
	{
		let plugins = JsonValue.MakeArray();
		for (let entry in session.Project.Settings.Plugins)
		{
			let json = JsonValue.MakeObject();
			EntryJson(session, entry, json);
			plugins.Add(json);
		}
		outResult.Set("platform", JsonValue.MakeString((session.Plugins != null) ? session.Plugins.Platform : PluginHost.HostPlatform));
		outResult.Set("plugins", plugins);

		// What the project could enable: its Plugins folder's packages and this host's linked
		// plugins that no entry names, each with why it is not offered when it is not.
		let found = scope List<AvailablePlugin>();
		defer { ClearAndDeleteItems!(found); }
		let parts = (session.PluginParts != null) ? (Span<PluginPart>)session.PluginParts : PluginRegistry.Parts;
		PluginDiscovery.Discover(session.Project.Directory, session.Project.Settings, parts, found);
		let available = JsonValue.MakeArray();
		for (let plugin in found)
		{
			let item = JsonValue.MakeObject();
			item.Set("id", JsonValue.MakeString(plugin.Id));
			item.Set("path", JsonValue.MakeString(plugin.Path));
			item.Set("name", JsonValue.MakeString(plugin.Name));
			item.Set("version", JsonValue.MakeString(plugin.Version));
			let kinds = JsonValue.MakeArray();
			for (let part in plugin.Parts)
				kinds.Add(JsonValue.MakeString(part));
			item.Set("parts", kinds);
			let platforms = JsonValue.MakeArray();
			for (let platform in plugin.Platforms)
				platforms.Add(JsonValue.MakeString(platform));
			item.Set("platforms", platforms);
			item.Set("offered", JsonValue.MakeBool(plugin.Problem.IsEmpty));
			if (!plugin.Problem.IsEmpty)
				item.Set("problem", JsonValue.MakeString(plugin.Problem));
			available.Add(item);
		}
		outResult.Set("available", available);
	}

	/// Saves the manifest after a change to the list and tells the host; the list, or why not.
	private static bool SaveList(ProjectSession session, JsonValue outResult, String outError)
	{
		if (session.Project.SaveSettings() case .Err)
		{
			outError.Append("the plugins changed but the manifest did not save (log_read says why)");
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		ListJson(session, outResult);
		return true;
	}

	private static bool Enable(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let id = arguments.Get("id").AsString();
		if (!PluginManifest.IsValidId(id))
		{
			outError.AppendF("'{}' is not a plugin id (lower case letters, digits and underscores, starting with a letter)", id);
			return false;
		}
		let existing = project.Settings.FindPlugin(id);
		let path = scope String();
		let platforms = scope List<String>();
		defer { ClearAndDeleteItems!(platforms); }
		if (existing != null)
		{
			path.Set(existing.Path);
			for (let platform in existing.Platforms)
				platforms.Add(new .(platform));
		}
		if (let given = arguments.Get("path"))
			path.Set(given.AsString());
		if (let given = arguments.Get("platforms"))
		{
			ClearAndDeleteItems!(platforms);
			for (int i < given.Count)
			{
				let platform = given.At(i);
				if (!platform.IsString)
				{
					outError.Append("`platforms` takes platform names (Linux64, Win64, Web)");
					return false;
				}
				bool listed = false;
				for (let known in platforms)
					listed |= (known == platform.AsString());
				if (!listed)
					platforms.Add(new .(platform.AsString()));
			}
		}
		// The manifest to check the platforms against: the package's own, else the host's.
		let package = scope PluginManifest();
		var manifest = (session.Plugins != null) ? session.Plugins.Manifest(id) : null;
		if (!path.IsEmpty)
		{
			let directory = PathJoin(project.Directory, path, .. scope .());
			if (PluginManifest.Load(directory, package) case .Err)
			{
				outError.AppendF("'{}' holds no plugin manifest (Plugin.xml) that reads", path);
				return false;
			}
			if (package.Id != id)
			{
				outError.AppendF("the package at '{}' is plugin '{}', not '{}'", path, package.Id, id);
				return false;
			}
			manifest = package;
		}
		if (manifest != null)
		{
			for (let platform in platforms)
			{
				if (manifest.FindPlatform(platform) != null)
					continue;
				let names = scope String();
				for (let supported in manifest.Platforms)
				{
					if (!names.IsEmpty)
						names.Append(", ");
					names.Append(supported.Platform);
				}
				outError.AppendF("plugin '{}' does not support {} (it supports: {})", id, platform, names.IsEmpty ? "none" : names);
				return false;
			}
		}
		var entry = existing;
		if (entry == null)
		{
			entry = new EnabledPlugin();
			entry.Id.Set(id);
			project.Settings.Plugins.Add(entry);
		}
		entry.Path.Set(path);
		ClearAndDeleteItems!(entry.Platforms);
		for (let platform in platforms)
			entry.Platforms.Add(new .(platform));
		return SaveList(session, outResult, outError);
	}

	private static bool SetSettings(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let id = arguments.Get("id").AsString();
		let entry = project.Settings.FindPlugin(id);
		if (entry == null)
		{
			outError.AppendF("the project enables no plugin '{}' (plugin_list names them)", id);
			return false;
		}
		let settings = LoadedSettings(session, id);
		if (settings == null)
		{
			let status = scope PluginStatus();
			PluginStatus.Of(entry, session.Plugins, status);
			if (status.State == .Loaded)
				outError.AppendF("plugin '{}' has no settings", id);
			else
				outError.AppendF("{}; its settings are kept as written", status.Reason);
			return false;
		}
		if (!session.Plugins.SettingsRead(id))
		{
			outError.AppendF("plugin '{}': its saved settings did not read as its settings type, so they are kept as written (log_read says why)", id);
			return false;
		}
		let fields = scope List<FieldInfo>();
		SettingFields.Of(settings.GetType(), fields);
		let given = arguments.Get("settings");
		let key = scope String();
		for (int i < given.Count)
		{
			let name = given.KeyAt(i);
			bool known = false;
			for (let field in fields)
			{
				SettingFields.Key(field, key..Clear());
				known |= (key == name);
			}
			if (known)
				continue;
			let names = scope String();
			for (let field in fields)
			{
				if (!names.IsEmpty)
					names.Append(", ");
				SettingFields.Key(field, names);
			}
			outError.AppendF("plugin '{}' has no setting '{}' (its settings: {})", id, name, names.IsEmpty ? "none" : names);
			return false;
		}
		// Everything is checked before anything changes: a refusal leaves the settings as they were.
		let changes = scope List<ReflectedFields.Change>();
		defer ClearAndDeleteItems(changes);
		if (!ReflectedFields.Check(given, fields, project.SourceDb, changes, outError))
			return false;
		ReflectedFields.Apply(settings, changes);
		if ((EnabledPlugin.WriteSettings((ISerializable)settings, entry.Settings) case .Err) || (project.SaveSettings() case .Err))
		{
			outError.AppendF("plugin '{}': the settings changed but the manifest did not save (log_read says why)", id);
			return false;
		}
		if (session.OnSettingsChanged != null)
			session.OnSettingsChanged();
		EntryJson(session, entry, outResult);
		return true;
	}
}
