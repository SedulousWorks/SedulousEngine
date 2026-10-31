using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Engine.Render;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// Project Settings (Raptor's editor-gui spec, 5.2, layer 6; ruling 20): the project's manifest
// (Project.xml) on the property grid, a window over its markup (Data/Editor/ProjectSettings.xml).
// The rows are a bag made from ProjectSettings' reflection (SettingFields), a section per category
// the settings name, each by its label: text, a number within its range, a check box, an enum's
// choices by name, and each asset setting an asset reference to the source type it names (a list
// of them for a list setting), so the slot picks, drops and clears as an inspector's does. MSAA's
// choices are the render subsystem's levels. The engine version the project was last saved with
// shows, read only. Save writes the rows back (a list's empty and repeated entries dropped), keeps
// the path mirrors beside the guids, persists the manifest and tells the editor (the context's
// settings-changed hook, which the session's settings-derived state follows); Cancel or closing
// leaves the manifest as it was.

class ProjectSettingsDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/ProjectSettings.xml";
	/// The path of the read-only row showing the engine version the project was saved with.
	public const String cEngineVersionRow = "engineVersion";
	/// The MSAA setting's key, whose choices are the render subsystem's levels.
	public const String cMsaaSetting = "renderMsaaSamples";
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
		mContext.SetStatus("Project settings saved.");
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
	}

	/// The row a setting is, or null for one no row shows (a text list: the MCP tools set it
	/// whole).
	private PropertyInfo AddRow(ProjectSettings settings, FieldInfo field, StringView name)
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

	/// The rows into `settings`: each setting a row shows and may edit.
	private void WriteBack(ProjectSettings settings)
	{
		if (mBag == null)
			return;
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let key = scope String();
		let path = scope String();
		for (let field in fields)
		{
			SettingFields.Key(field, key..Clear());
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
