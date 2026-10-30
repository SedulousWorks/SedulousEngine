using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The Project panel with a project open (Raptor's editor-gui spec, 5.1, layer 13). Its frame is
/// markup (Data/Editor/ProjectHome.gml); it fills the project's picture, name, engine and folder;
/// a Start column (open the default scene, the Game menu's actions, every scene in the project);
/// and a Project column (every setting the project's settings carry, by category, each asset a
/// link that opens it, a missing one in the warning colour, then the Project menu's actions).
/// Nothing here is a list of its own: the settings are ProjectSettings' [Setting] fields
/// (SettingFields), the actions the registry's Game and Project menus, the scenes the assets of
/// the default scene setting's type.
///
/// Refresh (each frame) fills it again when the settings changed (MarkChanged, from the settings'
/// save), the cook revision moved (assets added, renamed or removed) or the thumbnail changed.
class ProjectHomeView
{
	/// Its frame under the data root.
	public const String cMarkupPath = "Editor/ProjectHome.gml";

	/// Borrowed.
	private EditorContext mContext;
	/// Borrowed; null when there is none to watch.
	private EditorCookService mCook;
	/// What the header's picture shows: declared before the content, so they outlive it.
	private List<Sedulous.Image.Image> mPictures = new .() ~ DeleteContainerAndItems!(_);
	/// A reference of ours; the panel showing it takes its own.
	private Node mContent ~ _?.ReleaseRef();
	private delegate void(Guid id) mOnOpenAsset = null ~ delete _;
	private bool mChanged = false;
	private uint64 mCookRevision = 0;
	private int64 mThumbnailTime = 0;
	private List<Guid> mScenes = new .() ~ delete _;
	private List<String> mRows = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mActions = new .() ~ DeleteContainerAndItems!(_);

	/// Over `context`'s project, its frame `content` (the markup's: its parts by id); `cook`
	/// (nullable) says when the project's assets changed. TAKES OWNERSHIP of a reference to
	/// `content`; null fills nothing.
	public this(EditorContext context, EditorCookService cook, Node content)
	{
		mContext = context;
		mCook = cook;
		mContent = content;
		Rebuild();
	}

	/// Opens the asset with this guid in its page (the application's open path). TAKES OWNERSHIP
	/// of `open`.
	public void SetOnOpenAsset(delegate void(Guid id) open)
	{
		delete mOnOpenAsset;
		mOnOpenAsset = open;
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// The settings changed: filled again at the next Refresh.
	public void MarkChanged() => mChanged = true;

	/// Fills it again when something it shows changed (see the class comment).
	public void Refresh()
	{
		let revision = (mCook != null) ? mCook.Revision : 0;
		if (mChanged || (revision != mCookRevision) || (ThumbnailTime() != mThumbnailTime))
			Rebuild();
	}

	public void Rebuild()
	{
		mChanged = false;
		mCookRevision = (mCook != null) ? mCook.Revision : 0;
		mThumbnailTime = ThumbnailTime();
		mScenes.Clear();
		ClearAndDeleteItems(mRows);
		ClearAndDeleteItems(mActions);
		let project = mContext.Project;
		if ((mContent == null) || (project == null))
			return;
		Header(project);
		StartColumn(project);
		ProjectColumn(project);
	}

	/// What it shows, for tests: the scenes listed (in order), each setting row as
	/// "Label: value", and the actions offered (ids).
	public List<Guid> Scenes => mScenes;
	public List<String> SettingRows => mRows;
	public List<String> ActionIds => mActions;

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	/// Adds `child` to `into`, the tree's reference taking the place of the one it was made with.
	private static void Adopt(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}

	private int64 ThumbnailTime()
	{
		let project = mContext.Project;
		if (project == null)
			return 0;
		if (!FileStat(EditorProject.ThumbnailPath(project.Directory, .. scope .()), ?, let time))
			return 0;
		return time;
	}

	/// A label of `text` with the sheet's `classes`: a node with one reference, the caller's.
	private static Node Text(StringView text, StringView classes = default)
	{
		let label = new Sedulous.GUI.Label();
		label.Text = text;
		if (!classes.IsEmpty)
			label.AddClasses(classes);
		return label;
	}

	/// A link: a flat button of its text, at its own width. TAKES OWNERSHIP of `onClick`; a node
	/// with one reference, the caller's.
	private static Node Link(StringView text, StringView tooltip, delegate void() onClick)
	{
		let link = new Sedulous.GUI.Button();
		link.AddClass("link");
		link.Text = text;
		if (!tooltip.IsEmpty)
			link.Tooltip = tooltip;
		link.SetOnClick(onClick);
		return link;
	}

	private void OpenAsset(Guid id)
	{
		if (mOnOpenAsset != null)
			mOnOpenAsset(id);
	}

	/// An asset as a link that opens it; an unset one by `emptyText`, a missing one in the
	/// warning colour. A node with one reference, the caller's.
	private Node AssetLink(Guid id, StringView emptyText)
	{
		if (!id.IsSet)
			return Text(emptyText, "home-value dim");
		let instance = mContext.Project.SourceDb.GetInstance(id);
		if (instance == null)
			return Text("(missing)", "home-value missing");
		return Link(instance.Name, instance.GetPath(.. scope .()), new [=this, =id]() => { OpenAsset(id); });
	}

	/// The picture, the name, the engine and the folder.
	private void Header(EditorProject project)
	{
		let settings = project.Settings;
		if (let slot = Find<Node>("home-picture"))
		{
			slot.RemoveAllChildren(); // the pictures it showed go before their images
			ClearAndDeleteItems(mPictures);
			Adopt(slot, ProjectPicture.Make(project.Directory, settings.Name, "home-picture", mPictures));
		}
		if (let name = Find<Sedulous.GUI.Label>("home-name"))
			name.Text = settings.Name.IsEmpty ? "(unnamed)" : StringView(settings.Name);
		if (let engine = Find<Sedulous.GUI.Label>("home-engine"))
			engine.Text = scope $"SedulousEngine {settings.EngineVersion}";
		if (let folder = Find<Sedulous.GUI.Label>("home-folder"))
		{
			folder.Text = project.Directory;
			folder.Tooltip = project.Directory;
		}
	}

	/// The actions under `menu` ("Game/"), by their menu order, as buttons in `into`.
	private void MenuActions(StringView menu, Node into)
	{
		into.RemoveAllChildren();
		let found = scope List<EditorActionDeclaration>();
		for (let action in mContext.Actions.Actions)
		{
			if (action.MenuPath.StartsWith(menu))
				found.Add(action);
		}
		found.Sort(scope (a, b) => a.MenuOrder <=> b.MenuOrder);
		let context = mContext;
		for (let action in found)
		{
			let button = new Sedulous.GUI.Button();
			button.Text = action.Label;
			button.Tooltip = action.Description;
			button.Enabled = EditorActionRegistry.IsEnabled(action, null);
			let id = new String(action.Id);
			button.SetOnClick(new [=context, =id]() => { context.Actions.Execute(id, null).IgnoreError(); } ~ delete id);
			Adopt(into, button);
			mActions.Add(new String(action.Id));
		}
	}

	/// Open the default scene, play, and every scene in the project.
	private void StartColumn(EditorProject project)
	{
		let settings = project.Settings;
		if (let open = Find<Sedulous.GUI.Button>("home-open-default"))
		{
			let scene = settings.DefaultSceneId.IsSet ? project.SourceDb.GetInstance(settings.DefaultSceneId) : null;
			open.Text = (scene != null) ? scope:: $"Open {scene.Name}" : "No default scene";
			open.Enabled = scene != null;
			let id = settings.DefaultSceneId;
			open.SetOnClick(new [=this, =id]() => { OpenAsset(id); });
		}
		if (let game = Find<Node>("home-game-actions"))
			MenuActions("Game/", game);

		// The scenes: every asset of the type the default scene setting names.
		let list = Find<Node>("home-scenes");
		let heading = Find<Sedulous.GUI.Label>("home-scenes-heading");
		if (list == null)
			return;
		list.RemoveAllChildren();
		var sceneType = StringView();
		if (typeof(ProjectSettings).GetField("DefaultSceneId") case .Ok(let field))
		{
			let setting = SettingFields.Setting(field);
			if (setting.HasValue && (setting.Value.AssetType != null))
				sceneType = setting.Value.AssetType;
		}
		let scenes = scope List<Instance>();
		if (!sceneType.IsEmpty)
			CollectInstances(project.SourceDb.RootGroup, sceneType, scenes); // a group keeps its instances and its groups in name order, so the walk is in order
		if (heading != null)
			heading.Text = scope $"Scenes ({scenes.Count})";
		for (let scene in scenes)
		{
			let id = scene.Id;
			let isDefault = id == settings.DefaultSceneId;
			Adopt(list, Link(isDefault ? scope:: $"{scene.Name} (default)" : scene.Name, scene.GetPath(.. scope .()),
				new [=this, =id]() => { OpenAsset(id); }));
			mScenes.Add(id);
		}
		if (scenes.IsEmpty)
			Adopt(list, Text("No scenes yet.", "home-value dim"));
	}

	private static void CollectInstances(Group group, StringView typeName, List<Instance> outInstances)
	{
		for (let instance in group.Instances)
		{
			if (AssetTypeNames.Matches(instance.TypeName, typeName))
				outInstances.Add(instance);
		}
		for (let child in group.Groups)
			CollectInstances(child, typeName, outInstances);
	}

	/// A setting's value as text: a choice by its case's name, a flag as On or Off, a count (the
	/// MSAA level by its label, as the settings dialog shows it), a text ("Not set" when empty).
	/// Empty for a kind this page does not show.
	private static void SettingText(ProjectSettings settings, FieldInfo field, SettingKind kind, String outText)
	{
		let address = SettingFields.Address(settings, field);
		switch (kind)
		{
		case .Choice:
			let current = SettingFields.ReadChoice(settings, field);
			for (var (name, data) in Enum.GetEnumerator(field.FieldType))
			{
				if (data == current)
				{
					outText.Append(name);
					break;
				}
			}
		case .Flag:
			outText.Append(*(bool*)address ? "On" : "Off");
		case .Count:
			if (field.Name == "RenderMsaaSamples")
				outText.Append(MsaaLevels.All[MsaaLevels.IndexForSamples(*(uint32*)address)].Label);
			else
				outText.AppendF("{}", *(uint32*)address);
		case .Text:
			let text = *(String*)address;
			outText.Append(text.IsEmpty ? "Not set" : StringView(text));
		default:
		}
	}

	/// Every setting by category, then the Project menu's actions.
	private void ProjectColumn(EditorProject project)
	{
		let column = Find<Node>("home-settings");
		if (column == null)
			return;
		column.RemoveAllChildren();
		let settings = project.Settings;
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		// The categories in the order the settings first name them.
		let categories = scope List<StringView>();
		for (let field in fields)
		{
			let category = SettingFields.Category(field);
			if (!categories.Contains(category))
				categories.Add(category);
		}
		for (let category in categories)
		{
			Adopt(column, Text(category, "home-category"));
			for (let field in fields)
			{
				if (SettingFields.Category(field) != category)
					continue;
				let setting = SettingFields.Setting(field).Value;
				SettingFields.KindOf(field, let kind);
				let emptyText = (setting.EmptyText != null) ? StringView(setting.EmptyText) : "Not set";
				Node value = null;
				let text = scope String();
				switch (kind)
				{
				case .Asset:
					let id = *(Guid*)SettingFields.Address(settings, field);
					value = AssetLink(id, emptyText);
					let instance = id.IsSet ? project.SourceDb.GetInstance(id) : null;
					text.Append(!id.IsSet ? emptyText : (instance != null) ? instance.Name : "(missing)");
				case .AssetList:
					let ids = *(List<Guid>*)SettingFields.Address(settings, field);
					let list = new Sedulous.GUI.Panel();
					list.AddClass("home-links");
					for (let id in ids)
					{
						Adopt(list, AssetLink(id, "Not set"));
						let instance = project.SourceDb.GetInstance(id);
						if (!text.IsEmpty)
							text.Append(", ");
						text.Append((instance != null) ? instance.Name : "(missing)");
					}
					if (ids.IsEmpty)
					{
						text.Append("Not set");
						Adopt(list, Text(text, "home-value dim"));
					}
					value = list;
				default:
					SettingText(settings, field, kind, text);
					if (text.IsEmpty)
						continue; // a kind this page does not show
					value = Text(text, "home-value");
				}
				mRows.Add(new $"{setting.Label}: {text}");
				let row = new Sedulous.GUI.Panel();
				row.AddClass("home-setting");
				Adopt(row, Text(setting.Label, "home-label"));
				Adopt(row, value);
				Adopt(column, row);
			}
		}
		if (let actions = Find<Node>("home-project-actions"))
			MenuActions("Project/", actions);
	}
}
