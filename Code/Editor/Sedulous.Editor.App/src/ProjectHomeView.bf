using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The Project panel with a project open, in two columns
/// over its markup (Data/Editor/ProjectHome.xml). On the left the project: its picture, name,
/// location (under ~) and engine version, the settings that sum it up (those carrying a
/// [SettingSummary], by that label, each asset a link that opens it, a missing one in the warning
/// colour), and the player's window; Show in Folder and Project Settings under them. On the right
/// its scenes (the assets of the default scene setting's type), each a card that opens it, with its
/// thumbnail once the thumbnail service has one and its type's icon until then; or, with none, a
/// note with New Scene. Nothing here keeps a list of its own: the rows come from ProjectSettings'
/// reflection (SettingFields).
///
/// Refresh (each frame) fills it again when the settings changed (MarkChanged, from the settings'
/// save), the cook revision moved (assets added, renamed or removed) or the project's picture
/// changed, and asks again for the thumbnails the cards still lack.
class ProjectHomeView
{
	/// Its frame under the data root.
	public const String cMarkupPath = "Editor/ProjectHome.xml";

	/// A scene's card: where its thumbnail goes, and the icon shown until then (both the tree's).
	private class Card
	{
		public Guid Id;
		public Sedulous.GUI.Panel Picture;
		public Sedulous.GUI.Image Icon;
		public bool Shown = false;
	}

	/// Borrowed.
	private EditorContext mContext;
	/// Borrowed; null when there is none to watch.
	private EditorCookService mCook;
	/// What the picture shows: declared before the content, so they outlive it.
	private List<Sedulous.Image.Image> mPictures = new .() ~ DeleteContainerAndItems!(_);
	/// A reference of ours; the panel showing it takes its own.
	private Node mContent ~ _?.ReleaseRef();
	/// Shortens the location to ~.
	private String mHome = new .() ~ delete _;
	private delegate void(Guid id) mOnOpenAsset = null ~ delete _;
	private delegate void() mOnNewScene = null ~ delete _;
	private delegate void(StringView folder) mOnShowFolder = null ~ delete _;
	private delegate void() mOnProjectSettings = null ~ delete _;
	private bool mChanged = false;
	private uint64 mCookRevision = 0;
	private int64 mThumbnailTime = 0;
	private List<Guid> mScenes = new .() ~ delete _;
	private List<String> mRows = new .() ~ DeleteContainerAndItems!(_);
	private List<Card> mCards = new .() ~ DeleteContainerAndItems!(_);

	/// Over `context`'s project, its frame `content` (the markup's: its parts by id); `cook`
	/// (nullable) says when the project's assets changed. TAKES OWNERSHIP of a reference to
	/// `content`; null fills nothing.
	public this(EditorContext context, EditorCookService cook, Node content)
	{
		mContext = context;
		mCook = cook;
		mContent = content;
		GetHomeDirectory(mHome);
		if (let show = Find<Sedulous.GUI.Button>("home-show-folder"))
		{
			show.SetOnClick(new () =>
				{
					if ((mOnShowFolder != null) && (mContext.Project != null))
						mOnShowFolder(mContext.Project.Directory);
				});
		}
		if (let settings = Find<Sedulous.GUI.Button>("home-settings"))
		{
			settings.SetOnClick(new () =>
				{
					if (mOnProjectSettings != null)
						mOnProjectSettings();
				});
		}
		for (let id in StringView[2]("home-new-scene", "home-first-scene"))
		{
			if (let create = Find<Sedulous.GUI.Button>(id))
			{
				create.SetOnClick(new () =>
					{
						if (mOnNewScene != null)
							mOnNewScene();
					});
			}
		}
		Rebuild();
	}

	/// Opens the asset with this guid in its page (the application's open path). TAKES OWNERSHIP
	/// of `open`.
	public void SetOnOpenAsset(delegate void(Guid id) open)
	{
		delete mOnOpenAsset;
		mOnOpenAsset = open;
	}

	/// Makes a scene and opens it (File > New Scene). TAKES OWNERSHIP of `create`.
	public void SetOnNewScene(delegate void() create)
	{
		delete mOnNewScene;
		mOnNewScene = create;
	}

	/// Shows the project's folder in the system's file manager. TAKES OWNERSHIP of `show`.
	public void SetOnShowFolder(delegate void(StringView folder) show)
	{
		delete mOnShowFolder;
		mOnShowFolder = show;
	}

	/// Opens the Project Settings dialog. TAKES OWNERSHIP of `open`.
	public void SetOnProjectSettings(delegate void() open)
	{
		delete mOnProjectSettings;
		mOnProjectSettings = open;
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// The settings changed: filled again at the next Refresh.
	public void MarkChanged() => mChanged = true;

	/// Fills it again when something it shows changed (see the class comment), and shows the scene
	/// thumbnails that have become ready.
	public void Refresh()
	{
		let revision = (mCook != null) ? mCook.Revision : 0;
		if (mChanged || (revision != mCookRevision) || (ThumbnailTime() != mThumbnailTime))
			Rebuild();
		ShowThumbnails();
	}

	public void Rebuild()
	{
		mChanged = false;
		mCookRevision = (mCook != null) ? mCook.Revision : 0;
		mThumbnailTime = ThumbnailTime();
		mScenes.Clear();
		ClearAndDeleteItems(mRows);
		ClearAndDeleteItems(mCards);
		let project = mContext.Project;
		if ((mContent == null) || (project == null))
			return;
		Side(project);
		SceneCards(project);
		ShowThumbnails();
	}

	/// What it shows, for tests: the scenes (in order), each summary row as "Label: value", and
	/// how many cards show their thumbnail.
	public List<Guid> Scenes => mScenes;
	public List<String> SummaryRows => mRows;
	public int ThumbnailsShown
	{
		get
		{
			int shown = 0;
			for (let card in mCards)
				shown += card.Shown ? 1 : 0;
			return shown;
		}
	}

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
	private static Sedulous.GUI.Label Text(StringView text, StringView classes = default)
	{
		let label = new Sedulous.GUI.Label();
		label.Text = text;
		if (!classes.IsEmpty)
			label.AddClasses(classes);
		return label;
	}

	private void OpenAsset(Guid id)
	{
		if (mOnOpenAsset != null)
			mOnOpenAsset(id);
	}

	/// An asset setting's value: a link that opens the asset, its empty text when unset, or a
	/// warning when the asset is gone; `outText` gets what it says. A node with one reference, the
	/// caller's.
	private Node AssetValue(Guid id, StringView emptyText, String outText)
	{
		if (!id.IsSet)
		{
			outText.Append(emptyText);
			return Text(emptyText, "home-value dim");
		}
		let instance = mContext.Project.SourceDb.GetInstance(id);
		if (instance == null)
		{
			outText.Append("(missing)");
			return Text(outText, "home-value missing");
		}
		outText.Append(instance.Name);
		let link = new Sedulous.GUI.Button();
		link.AddClass("link");
		link.Text = instance.Name;
		link.Tooltip = instance.GetPath(.. scope .());
		link.SetOnClick(new [=this, =id] () => { OpenAsset(id); });
		return link;
	}

	/// A summary row: its label, its value (TAKEN), and "Label: text" for the tests.
	private void AddRow(Node summary, StringView label, Node value, StringView text)
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("home-row");
		Adopt(row, Text(label, "home-label"));
		Adopt(row, value);
		Adopt(summary, row);
		mRows.Add(new $"{label}: {text}");
	}

	/// The left column: the picture, the name, and the summary.
	private void Side(EditorProject project)
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
		let summary = Find<Node>("home-summary");
		if (summary == null)
			return;
		summary.RemoveAllChildren();
		let location = RecentProjects.ShortenHomePath(project.Directory, mHome, .. scope .());
		let place = Text(location, "home-value");
		place.Tooltip = project.Directory;
		AddRow(summary, "Location", place, location);
		AddRow(summary, "Engine version", Text(settings.EngineVersion, "home-value"), settings.EngineVersion);
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		for (let field in fields)
		{
			let label = SettingFields.Summary(field);
			if (label == null)
				continue;
			SettingFields.KindOf(field, let kind);
			if (kind != .Asset)
				continue; // the summary names assets; the window has its own row
			let setting = SettingFields.Setting(field).Value;
			let text = scope String();
			let value = AssetValue(*(Guid*)SettingFields.Address(settings, field), (setting.EmptyText != null) ? StringView(setting.EmptyText) : "Not set", text);
			AddRow(summary, label, value, text);
		}
		let window = settings.WindowSummary(.. scope .());
		AddRow(summary, "Window", Text(window, "home-value"), window);
	}

	/// The right column: a card per scene, or the note for a project with none.
	private void SceneCards(EditorProject project)
	{
		let settings = project.Settings;
		let grid = Find<Node>("home-scenes");
		if (grid == null)
			return;
		grid.RemoveAllChildren();
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
		if (let count = Find<Sedulous.GUI.Label>("home-scene-count"))
			count.Text = scope $"{scenes.Count}";
		let any = !scenes.IsEmpty;
		grid.Displayed = any;
		if (let none = Find<Node>("home-no-scenes"))
			none.Displayed = !any;
		if (let create = Find<Node>("home-new-scene"))
			create.Displayed = any; // with none, the note has its own
		let icon = scope String("Editor/Icons/Types/");
		if (sceneType.IsEmpty)
			icon.Append("Asset");
		else
			icon.Append(sceneType);
		icon.Append(".svg");
		for (let scene in scenes)
		{
			let id = scene.Id;
			let card = new Sedulous.GUI.Button();
			card.AddClass("home-scene");
			card.Tooltip = scene.GetPath(.. scope .());
			card.SetOnClick(new [=this, =id] () => { OpenAsset(id); });
			let picture = new Sedulous.GUI.Panel();
			picture.AddClass("home-scene-picture");
			picture.HitTestVisible = false;
			let stand = new Sedulous.GUI.Image();
			stand.AddClass("home-scene-icon");
			stand.Source = icon;
			Adopt(picture, stand);
			if (id == settings.DefaultSceneId)
				Adopt(picture, Text("Default", "badge info"));
			Adopt(card, picture);
			let body = new Sedulous.GUI.Panel();
			body.AddClass("home-scene-body");
			body.HitTestVisible = false;
			Adopt(body, Text(scene.Name, "home-scene-name"));
			Adopt(body, Text(scene.GetPath(.. scope .()), "home-scene-path"));
			Adopt(card, body);
			Adopt(grid, card);
			mScenes.Add(id);
			let entry = new Card();
			entry.Id = id;
			entry.Picture = picture;
			entry.Icon = stand;
			mCards.Add(entry);
		}
	}

	/// Puts each ready thumbnail in its card, in place of the type's icon.
	private void ShowThumbnails()
	{
		let thumbnails = mContext.Thumbnails;
		if (thumbnails == null)
			return;
		for (let card in mCards)
		{
			if (card.Shown)
				continue;
			let drawable = thumbnails.Get(card.Id);
			if (drawable == null)
				continue;
			let thumb = new Sedulous.GUI.Image();
			thumb.AddClass("home-scene-thumb");
			thumb.Fit = .Cover;
			thumb.SetDrawable(drawable);
			card.Icon.Displayed = false;
			card.Picture.AddChildAt(thumb, 0);
			thumb.ReleaseRef(); // the picture's keeps it
			card.Shown = true;
		}
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
}
