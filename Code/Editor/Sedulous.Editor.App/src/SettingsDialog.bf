using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Engine.Render;
using Sedulous.Engine.Project;
using Sedulous.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// Project Settings: the project's manifest (Project.xml) on the property grid, a window over its
// markup (Data/Editor/ProjectSettings.xml). The rows are a bag made from ProjectSettings'
// reflection (SettingFields), a section per category the settings name, each by its label: text, a
// number within its range, a check box, an enum's choices by name, and each asset setting an asset
// reference to the source type it names (a list of them for a list setting), so the slot picks,
// drops and clears as an inspector's does. MSAA's choices are the render subsystem's levels. The
// engine version the project was last saved with shows, read only. The project's plugins follow in
// their own section, a group per entry in its order under "In this project": an Enabled box, its
// state in the process's plugin host, and for a loaded plugin its settings, rows made the same way
// from its settings type; an entry whose plugin is not loaded keeps its settings as written. After
// them, under "Available", what the project could enable (PluginDiscovery, read from its Plugins
// folder each time the dialog opens): each package no entry names and each linked plugin no entry
// enables, unchecked, or with why it cannot be enabled. Save writes the rows back (a list's empty
// and repeated entries dropped), keeps the path mirrors beside the guids, writes each loaded
// plugin's settings into its entry, removes the entries left unchecked (a package's folder stays)
// and adds the plugins checked (on every platform their manifests support), persists the manifest
// and tells the editor (the context's settings-changed hook, which the session's settings-derived
// state follows); a changed plugin list takes effect when the project opens again. Cancel or
// closing leaves the manifest as it was.

class ProjectSettingsDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/ProjectSettings.xml";
	/// The path of the read-only row showing the engine version the project was saved with.
	public const String cEngineVersionRow = "engineVersion";
	/// The MSAA setting's key, whose choices are the render subsystem's levels.
	public const String cMsaaSetting = "renderMsaaSamples";
	/// The section the project's plugins show in; plugin `id`'s group is `plugins.<id>`, its state
	/// `plugins.<id>.state` and each setting `plugins.<id>.<name>`.
	public const String cPluginsCategory = "Plugins";
	/// The row the entries' groups sit under (`plugins.<id>`), and the one the plugins the project
	/// could enable sit under (`available.<n>`): the grid reaches a row through its parent's.
	public const String cPluginEntriesGroup = "plugins";
	public const String cAvailablePluginsGroup = "available";
	private const float cWidth = 620.0f;
	private const float cHeight = 480.0f;

	/// Borrowed.
	private EditorContext mContext;
	/// A reference of ours (the window holds its own).
	private Node mBody = null ~ _?.ReleaseRef();
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// Borrowed: the body's.
	private PropertyGrid mGrid = null;
	/// The rows, made again at each open from the manifest as it is then.
	private Sedulous.GUI.PropertyBag mBag = null ~ delete _;
	/// The source asset types the settings name, by the name they give, resolved once each (a walk
	/// of the type table); null for a name no type has.
	private Dictionary<String, Type> mSourceTypes = new .() ~ DeleteDictionaryAndKeys!(_);
	/// The loaded plugins whose settings the rows show: their ids, and the objects the rows write
	/// into (the plugin host's, alive while the plugin is enabled).
	private List<String> mPluginIds = new .() ~ DeleteContainerAndItems!(_);
	private List<Object> mPluginSettings = new .() ~ delete _;
	/// What the project could enable, read at each open.
	private List<AvailablePlugin> mAvailable = new .() ~ DeleteContainerAndItems!(_);

	/// The plugin parts the editor links, which the project may enable; null is the parts that
	/// registered in this binary (PluginRegistry). BORROWED.
	public List<PluginPart> LinkedParts = null;

	/// The dialog over `context`'s project, its body `body` (the markup's controls by id). `refs`
	/// (what the asset slots ask of the editor) outlives it. TAKES OWNERSHIP of a reference to
	/// `body`; null makes a dialog that never opens.
	public this(EditorContext context, ResourceRefServices refs, Node body)
	{
		mContext = context;
		mBody = body;
		if (mBody == null)
			return;
		mGrid = Find<PropertyGrid>("settings-grid");
		if (mGrid != null)
		{
			ResourceRefEditor.Register(mGrid.Editors, refs);
			mGrid.Refresh(); // the rows' pools again, with the slot among them
		}
		mWindow = new Sedulous.GUI.Window();
		mWindow.Title = "Project Settings";
		mWindow.AddClass("project-settings-window");
		mWindow.Size = .(cWidth, cHeight);
		mWindow.Content.AddChild(mBody);
		if (let save = Find<Sedulous.GUI.Button>("settings-save"))
			save.SetOnClick(new () => { Save(); });
		if (let cancel = Find<Sedulous.GUI.Button>("settings-cancel"))
			cancel.SetOnClick(new () => { Close(); });
	}

	public ~this()
	{
		Close();
		// The grid may outlive this (the window's exit playing): it lets go of the bag first.
		if (mGrid != null)
			mGrid.Source = null;
	}

	/// Opens it over `root` as a modal window, the rows the manifest as it is; false with no
	/// markup, no project, or when it is open already.
	public bool Open(Node root)
	{
		if ((mWindow == null) || mWindow.IsOpen || (mContext.Project == null))
			return false;
		if (mGrid != null)
			mGrid.Source = null; // the rows are made again, from the manifest as it is
		Fill(mContext.Project.Settings);
		if (mGrid != null)
			mGrid.Source = mBag;
		OpenPluginGroups();
		mWindow.OpenModal(root);
		return mWindow.IsOpen;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	/// Closes it, the manifest as it was: nothing is written until Save.
	public void Close()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// Writes the rows into the manifest, keeps the path mirrors, persists it, tells the editor and
	/// closes; false when there is no project (it closes) or the manifest could not be written (it
	/// stays open, the editor told).
	public bool Save()
	{
		let project = mContext.Project;
		if (project == null)
		{
			Close();
			return false;
		}
		let settings = project.Settings;
		WriteBack(settings);
		let pluginsChanged = ApplyPluginChanges(settings);
		// The source-database path mirrors, for display and the older manifest fallback.
		settings.RefreshPathMirrors(scope (id, outPath) =>
			{
				if (let instance = project.SourceDb.GetInstance(id))
					instance.GetPath(outPath);
			});
		if (project.SaveSettings() case .Err)
		{
			mContext.Notify(.Error, "Project settings save FAILED (see console).");
			return false;
		}
		mContext.SetStatus(pluginsChanged ? "Project settings saved. The plugins changed: they load when the project opens again (a package of the project's in its own build, Project > Build Project)." : "Project settings saved.");
		// Settings-derived session state (the default UI font and theme binds) re-applies now;
		// without this a changed default font kept the old bind until reopen.
		mContext.NotifyProjectSettingsChanged();
		GlobalLog(.Information, "Project: settings saved (default scene: {})",
			settings.DefaultScene.IsEmpty ? "(none)" : StringView(settings.DefaultScene));
		Close();
		return true;
	}

	/// The rows (the bag the grid shows); null before the first open. The dialog's.
	public Sedulous.GUI.PropertyBag Rows => mBag;
	/// The grid the rows show in; null with no markup. The body's.
	public PropertyGrid Grid => mGrid;
	/// The window (its controls by id, for a test); null with no markup. The dialog's.
	public Sedulous.GUI.Window Window => mWindow;

	private T Find<T>(StringView id) where T : Node => (mBody != null) ? mBody.FindElement(id) as T : null;

	/// A guid as a reference row holds it: its text, empty for none.
	private static void GuidText(Guid id, String outText)
	{
		if (!id.IsNil)
			id.ToString(outText);
	}

	/// What a reference row's text names: nil for none, or text that is no guid.
	private static Guid ParseGuid(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		if (!trimmed.IsEmpty && (Guid.Parse(trimmed) case .Ok(let id)))
			return id;
		return .Empty;
	}

	/// The source asset type a setting names, by its full or its short name (the settings give the
	/// short one, "SceneDocument"); null when no type has it.
	private Type SourceTypeNamed(StringView name)
	{
		if (name.IsEmpty)
			return null;
		if (mSourceTypes.TryGetValue(scope String(name), let known))
			return known;
		Type found = null;
		let text = scope String();
		for (let type in Type.Types)
		{
			// As the page registry's walk: what is no named type instance (a tuple's GetName
			// fatals) cannot be an asset type.
			if (!(type is TypeInstance) || type.IsBoxed || type.IsPointer || type.IsArray
				|| type.IsSizedArray || type.IsGenericParam || type.IsTuple)
				continue;
			text.Clear();
			type.GetFullName(text);
			if (AssetTypeNames.Matches(text, name))
			{
				found = type;
				break;
			}
		}
		mSourceTypes[new String(name)] = found;
		return found;
	}

	/// A row per labelled setting, in its category, from the manifest's values; then the engine
	/// version, read only, under the first category.
	private void Fill(ProjectSettings settings)
	{
		delete mBag;
		mBag = new .();
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let key = scope String();
		for (let field in fields)
		{
			let setting = SettingFields.Setting(field).Value;
			if (setting.Label == null)
				continue;
			SettingFields.Key(field, key..Clear());
			let row = AddRow(settings, field, key);
			if (row == null)
				continue;
			row.DisplayName.Set(setting.Label);
			row.Category.Set(SettingFields.Category(field));
		}
		// What last saved it; a save stamps the running engine.
		let version = mBag.Add(cEngineVersionRow, .String, Sedulous.GUI.Variant(settings.EngineVersion));
		version.DisplayName.Set("Engine version");
		version.Category.Set(SettingFields.cDefaultCategory);
		version.Description.Set("The engine this project was last saved with; a save stamps the running one.");
		version.ReadOnly = true;
		FillPlugins(settings);
	}

	/// A group per plugin entry: whether it stays enabled, its state, and a loaded plugin's
	/// settings; then a group per plugin the project could enable.
	private void FillPlugins(ProjectSettings settings)
	{
		ClearAndDeleteItems!(mPluginIds);
		mPluginSettings.Clear();
		let host = mContext.Plugins;
		let path = scope String();
		if (!settings.Plugins.IsEmpty)
		{
			let entries = mBag.Add(cPluginEntriesGroup, .Group);
			entries.DisplayName.Set("In this project");
			entries.Category.Set(cPluginsCategory);
		}
		for (let entry in settings.Plugins)
		{
			let group = scope $"{cPluginEntriesGroup}.{entry.Id}";
			let manifest = (host != null) ? host.Manifest(entry.Id) : null;
			let header = mBag.Add(group, .Group);
			header.DisplayName.Set(((manifest != null) && !manifest.Name.IsEmpty) ? StringView(manifest.Name) : StringView(entry.Id));
			header.Category.Set(cPluginsCategory);
			let enabled = mBag.Add(scope $"{group}.enabled", .Bool, Sedulous.GUI.Variant(true));
			enabled.DisplayName.Set("Enabled");
			enabled.Category.Set(cPluginsCategory);
			enabled.Description.Set("Unchecked, Save removes it and its settings from the project; a package's folder stays.");
			let status = scope Sedulous.Engine.Project.PluginStatus();
			Sedulous.Engine.Project.PluginStatus.Of(entry, host, status);
			let state = scope String(status.State.Name);
			if (!status.Reason.IsEmpty)
				state.AppendF(": {}", status.Reason);
			for (let platform in status.UnsupportedPlatforms)
				state.AppendF("; {} is not a platform it supports", platform);
			let stateRow = mBag.Add(scope $"{group}.state", .String, Sedulous.GUI.Variant(state));
			stateRow.DisplayName.Set("State");
			stateRow.Category.Set(cPluginsCategory);
			stateRow.ReadOnly = true;
			let object = (host != null) ? host.Settings(entry.Id) : null;
			if ((object == null) || !host.SettingsRead(entry.Id))
				continue; // kept as written
			mPluginIds.Add(new .(entry.Id));
			mPluginSettings.Add(object);
			let fields = scope List<FieldInfo>();
			SettingFields.Of(object.GetType(), fields);
			for (let field in fields)
			{
				let setting = SettingFields.Setting(field).Value;
				if (setting.Label == null)
					continue;
				path..Clear()..AppendF("{}.", group);
				SettingFields.Key(field, path);
				let row = AddRow(object, field, path);
				if (row == null)
					continue;
				row.DisplayName.Set(setting.Label);
				row.Category.Set(cPluginsCategory);
			}
		}
		FillAvailablePlugins(settings);
	}

	/// Opens the plugins' groups (groups start folded), so each one's Enabled box shows.
	private void OpenPluginGroups()
	{
		if ((mGrid == null) || (mContext.Project == null))
			return;
		mGrid.SetOpen(cPluginEntriesGroup, true);
		mGrid.SetOpen(cAvailablePluginsGroup, true);
		for (let entry in mContext.Project.Settings.Plugins)
			mGrid.SetOpen(scope $"{cPluginEntriesGroup}.{entry.Id}", true);
		for (int i < mAvailable.Count)
			mGrid.SetOpen(scope $"{cAvailablePluginsGroup}.{i}", true);
	}

	/// A group per plugin the project could enable (`available.<n>`, PluginDiscovery): unchecked,
	/// with what it is, or with why it cannot be enabled.
	private void FillAvailablePlugins(ProjectSettings settings)
	{
		ClearAndDeleteItems!(mAvailable);
		let project = mContext.Project;
		if (project == null)
			return;
		let linked = (LinkedParts != null) ? (Span<PluginPart>)LinkedParts : PluginRegistry.Parts;
		PluginDiscovery.Discover(project.Directory, settings, linked, mAvailable);
		if (!mAvailable.IsEmpty)
		{
			let available = mBag.Add(cAvailablePluginsGroup, .Group);
			available.DisplayName.Set("Available");
			available.Category.Set(cPluginsCategory);
		}
		for (int i < mAvailable.Count)
		{
			let plugin = mAvailable[i];
			let group = scope $"{cAvailablePluginsGroup}.{i}";
			let header = mBag.Add(group, .Group);
			// Its name and version, then where it is: its folder, or linked; a package whose
			// manifest does not read is only its folder.
			if (plugin.Id.IsEmpty)
				header.DisplayName.Set(plugin.Path);
			else
			{
				header.DisplayName.Set(!plugin.Name.IsEmpty ? StringView(plugin.Name) : StringView(plugin.Id));
				if (!plugin.Version.IsEmpty)
					header.DisplayName.AppendF(" {}", plugin.Version);
				if (plugin.Path.IsEmpty)
					header.DisplayName.Append(" (linked)");
				else
					header.DisplayName.AppendF(" ({})", plugin.Path);
			}
			header.Category.Set(cPluginsCategory);
			let state = scope String();
			if (plugin.Problem.IsEmpty)
			{
				let enabled = mBag.Add(scope $"{group}.enabled", .Bool, Sedulous.GUI.Variant(false));
				enabled.DisplayName.Set("Enabled");
				enabled.Category.Set(cPluginsCategory);
				enabled.Description.Set("Checked, Save enables it in the project; it loads when the project opens again (a package of the project's in its own build: Project > Build Project).");
				state.Append("available:");
				for (int k < plugin.Parts.Count)
					state.AppendF("{}{}", (k == 0) ? " " : ", ", plugin.Parts[k]);
				state.Append((plugin.Parts.Count == 1) ? " part on" : " parts on");
				for (int k < plugin.Platforms.Count)
					state.AppendF("{}{}", (k == 0) ? " " : ", ", plugin.Platforms[k]);
			}
			else
			{
				state.AppendF("not offered: {}", plugin.Problem);
			}
			let stateRow = mBag.Add(scope $"{group}.state", .String, Sedulous.GUI.Variant(state));
			stateRow.DisplayName.Set("State");
			stateRow.Category.Set(cPluginsCategory);
			stateRow.ReadOnly = true;
		}
	}

	/// The entries left unchecked go, with their settings (a package's folder stays); the plugins
	/// checked join, on every platform their manifests support. Whether anything changed.
	private bool ApplyPluginChanges(ProjectSettings settings)
	{
		bool changed = false;
		for (int i = settings.Plugins.Count - 1; i >= 0; i--)
		{
			let path = scope $"{cPluginEntriesGroup}.{settings.Plugins[i].Id}.enabled";
			if (mBag.FindInfo(path) == null)
				continue;
			var value = mBag.GetValue(path, 0);
			defer value.Dispose();
			if (value.AsBool)
				continue;
			delete settings.Plugins[i];
			settings.Plugins.RemoveAt(i);
			changed = true;
		}
		for (int i < mAvailable.Count)
		{
			let plugin = mAvailable[i];
			let path = scope $"{cAvailablePluginsGroup}.{i}.enabled";
			if (!plugin.Problem.IsEmpty || (mBag.FindInfo(path) == null) || (settings.FindPlugin(plugin.Id) != null))
				continue;
			var value = mBag.GetValue(path, 0);
			defer value.Dispose();
			if (!value.AsBool)
				continue;
			let entry = new EnabledPlugin();
			entry.Id.Set(plugin.Id);
			entry.Path.Set(plugin.Path);
			settings.Plugins.Add(entry);
			changed = true;
		}
		return changed;
	}

	/// The row a setting is, or null for one no row shows (a text list: the MCP tools set it
	/// whole).
	private PropertyInfo AddRow(Object settings, FieldInfo field, StringView name)
	{
		SettingFields.KindOf(field, let kind);
		let setting = SettingFields.Setting(field).Value;
		let address = SettingFields.Address(settings, field);
		let text = scope String();
		switch (kind)
		{
		case .Asset:
			GuidText(*(Guid*)address, text);
			let row = mBag.Add(name, .Reference, Sedulous.GUI.Variant(text));
			row.ReferenceType = SourceTypeNamed(setting.AssetType);
			if (setting.EmptyText != null)
				row.Description.AppendF("None is {}", setting.EmptyText);
			return row;
		case .AssetList:
			let ids = *(List<Guid>*)address;
			let row = mBag.AddList(name, .Reference, Sedulous.GUI.Variant(StringView()), ids.Count);
			let path = scope String();
			for (int i < ids.Count)
			{
				path..Clear()..AppendF("{}.{}", name, i);
				GuidText(ids[i], text..Clear());
				mBag.SetValue(path, 0, Sedulous.GUI.Variant(text));
			}
			if (let element = mBag.FindElementInfo(name))
				element.ReferenceType = SourceTypeNamed(setting.AssetType);
			return row;
		case .Count:
			let value = *(uint32*)address;
			if (name == cMsaaSetting)
			{
				// The level a stored count selects: a four the four times level, a three two times
				// rather than nothing (MsaaLevels.IndexForSamples).
				let level = MsaaLevels.All[MsaaLevels.IndexForSamples(value)];
				let msaa = mBag.Add(name, .Enum, Sedulous.GUI.Variant((int64)level.Samples));
				for (let choice in MsaaLevels.All)
					msaa.AddChoice(choice.Label, (int64)choice.Samples);
				return msaa;
			}
			let row = mBag.Add(name, .Integer, Sedulous.GUI.Variant((int64)value));
			if (field.GetCustomAttribute<RangeAttribute>() case .Ok(let range))
			{
				row.HasRange = true;
				row.Min = range.Min;
				row.Max = range.Max;
				row.Step = range.Step;
			}
			return row;
		case .Choice:
			let row = mBag.Add(name, .Enum, Sedulous.GUI.Variant(SettingFields.ReadChoice(settings, field)));
			for (var (caseName, data) in Enum.GetEnumerator(field.FieldType))
				row.AddChoice(caseName, data);
			return row;
		case .Flag:
			return mBag.Add(name, .Bool, Sedulous.GUI.Variant(*(bool*)address));
		case .Text:
			let current = *(String*)address;
			return mBag.Add(name, .String, Sedulous.GUI.Variant(current));
		default:
			return null;
		}
	}

	/// The rows into `settings`, and each loaded plugin's into its object and its entry.
	private void WriteBack(ProjectSettings settings)
	{
		if (mBag == null)
			return;
		WriteRows(settings, "");
		for (int i < mPluginIds.Count)
		{
			let entry = settings.FindPlugin(mPluginIds[i]);
			if (entry == null)
				continue;
			WriteRows(mPluginSettings[i], scope $"plugins.{mPluginIds[i]}");
			if (EnabledPlugin.WriteSettings((ISerializable)mPluginSettings[i], entry.Settings) case .Err)
				GlobalLog(.Error, "Editor: plugin '{}': its settings did not write into the project", mPluginIds[i]);
		}
	}

	/// The rows under `group` (top level when empty) into `settings`: each setting a row shows and
	/// may edit.
	private void WriteRows(Object settings, StringView group)
	{
		let fields = scope List<FieldInfo>();
		SettingFields.Of(settings.GetType(), fields);
		let key = scope String();
		let path = scope String();
		for (let field in fields)
		{
			key.Clear();
			if (!group.IsEmpty)
				key.AppendF("{}.", group);
			SettingFields.Key(field, key);
			let info = mBag.FindInfo(key);
			if ((info == null) || info.ReadOnly)
				continue;
			SettingFields.KindOf(field, let kind);
			let address = SettingFields.Address(settings, field);
			var value = mBag.GetValue(key, 0);
			defer value.Dispose();
			switch (kind)
			{
			case .Asset:
				*(Guid*)address = ParseGuid(value.AsString); // empty: none
			case .AssetList:
				let ids = *(List<Guid>*)address;
				ids.Clear();
				for (int i < mBag.ElementCount(key, 0))
				{
					var element = mBag.GetValue(path..Clear()..AppendF("{}.{}", key, i), 0);
					let id = ParseGuid(element.AsString);
					element.Dispose();
					// A slot never picked is dropped, and an asset listed twice is listed once.
					if (id.IsSet && !ids.Contains(id))
						ids.Add(id);
				}
			case .Count:
				// Held within its range: the bag keeps whatever it is given.
				SettingFields.CountRange(field, let least, let most);
				*(uint32*)address = (uint32)Math.Max((int64)least, Math.Min(value.AsInt, (int64)most));
			case .Choice:
				SettingFields.WriteChoice(settings, field, value.AsInt);
			case .Flag:
				*(bool*)address = value.AsBool;
			case .Text:
				(*(String*)address).Set(value.AsString);
			default:
			}
		}
	}
}
