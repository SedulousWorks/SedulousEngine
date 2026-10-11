using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.UI;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// The Project page, in the panel that holds the document area's place (with every page
/// closed, a newly opened one docks beside it rather than among the tool panels). It shows the
/// open project: its picture, name, engine and folder; a Start column (open the default scene,
/// the Game menu's actions, every scene in the project); and a Project column (every setting
/// the project's settings carry, by category, each asset a link that opens it, then the
/// Project menu's actions). Nothing here is a list of its own: the settings are
/// ProjectSettings' [Setting] fields (SettingFields), the actions the registry's Game and
/// Project menus, the scenes the assets of the default scene setting's type.
///
/// Refresh (each frame) rebuilds it when the settings changed (MarkChanged, from the settings'
/// save), the cook revision moved (assets added, renamed or removed) or the thumbnail changed.
class ProjectHomeView
{
	/// Opens the asset with this guid in its page (the app's open path). Owned.
	public delegate void(Guid id) OnOpenAsset ~ delete _;

	private static readonly Color cDim = .(0.55f, 0.55f, 0.57f, 1.0f);
	private static readonly Color cMissing = .(0.95f, 0.6f, 0.35f, 1.0f);
	/// A link's padding: its hover fill around the text.
	private const float cLinkInsetX = 6.0f;
	private const float cLinkInsetY = 3.0f;

	/// Borrowed.
	private EditorContext mContext;
	/// Borrowed; null when there is none to watch.
	private EditorCookService mCook;
	/// One reference, the panel showing it taking its own.
	private ScrollView mScroll ~ _.ReleaseRef();
	/// The scroll's one child, refilled by Rebuild. Borrowed: the scroll owns it.
	private FlexLayout mPage;
	/// What the header's picture borrows.
	private List<Image> mPictures = new .() ~ DeleteContainerAndItems!(_);
	private bool mChanged = false;
	private uint64 mCookRevision = 0;
	private int64 mThumbnailTime = 0;
	private List<Guid> mScenes = new .() ~ delete _;
	private List<String> mRows = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mActions = new .() ~ DeleteContainerAndItems!(_);

	/// `cook` (nullable) tells when the project's assets changed.
	public this(EditorContext context, EditorCookService cook)
	{
		mContext = context;
		mCook = cook;
		mScroll = new ScrollView();
		mScroll.VScrollBarPolicy.Value = .Auto;
		mScroll.HScrollBarPolicy.Value = .Never;
		mPage = new FlexLayout();
		mPage.Direction = .Vertical;
		mPage.Spacing = 22;
		mPage.Padding = .(28, 24);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		mScroll.AddView(mPage, match);
		Rebuild();
	}

	/// The page's view. Borrowed: a caller that keeps it takes a reference.
	public View View => mScroll;

	/// The settings changed: rebuild at the next Refresh.
	public void MarkChanged() => mChanged = true;

	/// Rebuilds when something it shows changed (see the class comment).
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
		mPage.RemoveAllViews();
		ClearAndDeleteItems(mPictures); // the views showing them went with the page
		mScenes.Clear();
		ClearAndDeleteItems(mRows);
		ClearAndDeleteItems(mActions);

		let project = mContext.Project;
		if (project == null)
		{
			mPage.AddView(Text("No project is open.", 13.0f, cDim));
			return;
		}
		mPage.AddView(Header(project));

		let columns = new FlexLayout();
		columns.Direction = .Horizontal;
		columns.Wrap = true;
		columns.Spacing = 40;
		columns.LineSpacing = 22;
		var start = LayoutStyle();
		start.Width = SizeSpec.Fixed(Unit.Dp(280.0f));
		columns.AddView(StartColumn(project), start);
		var settings = LayoutStyle();
		settings.Width = SizeSpec.Fixed(Unit.Dp(440.0f));
		columns.AddView(ProjectColumn(project), settings);
		mPage.AddView(columns);
	}

	/// What it shows, for tests: the scenes listed (in order), each setting row as
	/// "Label: value", and the actions offered (ids).
	public List<Guid> Scenes => mScenes;
	public List<String> SettingRows => mRows;
	public List<String> ActionIds => mActions;

	private int64 ThumbnailTime()
	{
		let project = mContext.Project;
		if (project == null)
			return 0;
		if (!FileStat(EditorProject.ThumbnailPath(project.Directory, .. scope .()), ?, let time))
			return 0;
		return time;
	}

	private static Label Text(StringView text, float size, Color? color = null)
	{
		let label = new Label(text);
		label.FontSize.Value = size;
		if (color.HasValue)
			label.TextColor.Value = color;
		return label;
	}

	/// A setting's value as plain text, inset as a link's text is, so the column lines up.
	private static View Value(StringView text, Color? color = null)
	{
		let label = Text(text, 13.0f, color);
		label.Ellipsis.Value = true;
		var inset = LayoutStyle();
		inset.Margin = Thickness(cLinkInsetX, cLinkInsetY);
		label.SetLayout(inset);
		return label;
	}

	private static Label Heading(StringView text) => Text(text, 11.5f, cDim);

	/// A quiet button as wide as its text: a link to an asset or a scene. (A content button
	/// centres its content, so a link is placed at its own width, at the start of its line.)
	/// `onClick` is consumed.
	private static ContentButton Link(StringView text, delegate void() onClick)
	{
		let label = Text(text, 13.0f);
		label.Ellipsis.Value = true;
		let button = new ContentButton(label);
		button.SetStyle(.Padding, Thickness(cLinkInsetX, cLinkInsetY));
		let look = new StateListDrawable();
		look.Set(.Normal, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.0f), 4.0f));
		look.Set(.Hover, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.07f), 4.0f));
		look.Set(.Pressed, new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, 0.11f), 4.0f));
		button.SetStyle(.Background, look);
		button.OnClick.Add(new [=onClick](b) => { onClick(); } ~ delete onClick);
		return button;
	}

	private void OpenAsset(Guid id)
	{
		if (OnOpenAsset != null)
			OnOpenAsset(id);
	}

	private View AssetLink(Guid id, StringView emptyText)
	{
		if (id == Guid.Empty)
			return Value(emptyText, cDim);
		let instance = mContext.Project.SourceDb.GetInstance(id);
		if (instance == null)
			return Value("(missing)", cMissing);
		let link = Link(instance.Name, new [=this, =id]() => { OpenAsset(id); });
		instance.GetPath(link.TooltipText);
		return link;
	}

	/// The picture, the name, the engine and the folder.
	private View Header(EditorProject project)
	{
		let settings = project.Settings;
		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.AlignItems = .Center;
		header.Spacing = 18;
		header.AddView(ProjectPicture.Make(project.Directory, settings.Name, 192.0f, 108.0f, 8.0f, mPictures));
		let text = new FlexLayout();
		text.Direction = .Vertical;
		text.Spacing = 4;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		let name = Text(settings.Name.IsEmpty ? "(unnamed)" : StringView(settings.Name), 22.0f);
		name.Ellipsis.Value = true;
		text.AddView(name, match);
		text.AddView(Text(scope $"SedulousEngine {settings.EngineVersion}", 12.5f, cDim));
		let folder = Text(project.Directory, 12.0f, cDim);
		folder.Ellipsis.Value = true;
		folder.TooltipText.Set(project.Directory);
		text.AddView(folder, match);
		var grow = LayoutStyle();
		grow.FlexBasis = Unit.Dp(0.0f);
		grow.FlexGrow = 1.0f;
		header.AddView(text, grow);
		return header;
	}

	/// The actions under `menu` ("Game/"), by their menu order, as a row of buttons.
	private View MenuActions(StringView menu)
	{
		let found = scope List<EditorActionDeclaration>();
		for (let action in mContext.Actions.Actions)
		{
			if (action.MenuPath.StartsWith(menu))
				found.Add(action);
		}
		found.Sort(scope (a, b) => a.MenuOrder <=> b.MenuOrder);
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Wrap = true;
		row.Spacing = 6;
		row.LineSpacing = 6;
		for (let action in found)
		{
			let button = new Button(action.Label);
			button.TooltipText.Set(action.Description);
			button.IsEnabled = EditorActionRegistry.IsEnabled(action, null);
			let id = new String(action.Id);
			button.OnClick.Add(new [=this, =id](b) => { mContext.Actions.Execute(id, null); } ~ delete id);
			var height = LayoutStyle();
			height.Height = SizeSpec.Fixed(Unit.Dp(28.0f));
			row.AddView(button, height);
			mActions.Add(new String(action.Id));
		}
		return row;
	}

	/// Open the default scene, play, and every scene in the project.
	private View StartColumn(EditorProject project)
	{
		let settings = project.Settings;
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8;
		column.AddView(Heading("START"));
		{
			let scene = (settings.DefaultSceneId == Guid.Empty) ? null : project.SourceDb.GetInstance(settings.DefaultSceneId);
			let open = new Button((scene != null) ? scope:: $"Open {scene.Name}" : "No default scene");
			open.IsEnabled = scene != null;
			let id = settings.DefaultSceneId;
			open.OnClick.Add(new [=this, =id](b) => { OpenAsset(id); });
			var height = LayoutStyle();
			height.Height = SizeSpec.Fixed(Unit.Dp(30.0f));
			column.AddView(open, height);
		}
		column.AddView(MenuActions("Game/"));

		// The scenes: every asset of the type the default scene setting names.
		var sceneType = StringView();
		if (typeof(ProjectSettings).GetField("DefaultSceneId") case .Ok(let field))
		{
			let setting = SettingFields.Setting(field);
			if (setting.HasValue && (setting.Value.AssetType != null))
				sceneType = setting.Value.AssetType;
		}
		if (sceneType.IsEmpty)
			return column;
		let scenes = scope List<Instance>();
		// A group keeps its instances and its groups in name order, so the walk is in order.
		CollectInstances(project.SourceDb.RootGroup, sceneType, scenes);
		let spacer = new FlexLayout();
		spacer.Padding = .(0, 8, 0, 0);
		spacer.AddView(Heading(scope $"SCENES ({scenes.Count})"));
		column.AddView(spacer);
		for (let scene in scenes)
		{
			let id = scene.Id;
			let isDefault = id == settings.DefaultSceneId;
			let link = Link(isDefault ? scope:: $"{scene.Name}  (default)" : scene.Name, new [=this, =id]() => { OpenAsset(id); });
			scene.GetPath(link.TooltipText);
			var start = LayoutStyle();
			start.AlignSelf = .Start;
			column.AddView(link, start);
			mScenes.Add(id);
		}
		if (scenes.IsEmpty)
			column.AddView(Text("No scenes yet.", 13.0f, cDim));
		return column;
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

	/// A setting's value as text: a choice by its case's name, a flag as On or Off, a count,
	/// a text ("(none)" when empty). Empty for a kind this page does not show.
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
			if (field.Name == "RenderMsaaSamples") // by its level's label, as the dialog shows it
				outText.Append(MsaaLevels.All[MsaaLevels.IndexForSamples(*(uint32*)address)].Label);
			else
				outText.AppendF("{}", *(uint32*)address);
		case .Text:
			let text = *(String*)address;
			outText.Append(text.IsEmpty ? "(none)" : StringView(text));
		default:
		}
	}

	/// Every setting by category, then the Project menu's actions.
	private View ProjectColumn(EditorProject project)
	{
		let settings = project.Settings;
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4;
		column.AddView(Heading("PROJECT"));

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
			let pad = new FlexLayout();
			pad.Padding = .(0, 8, 0, 2);
			pad.AddView(Text(category, 13.0f, Color(0.8f, 0.8f, 0.82f, 1.0f)));
			column.AddView(pad);
			for (let field in fields)
			{
				if (SettingFields.Category(field) != category)
					continue;
				let setting = SettingFields.Setting(field).Value;
				SettingFields.KindOf(field, let kind);
				let emptyText = (setting.EmptyText != null) ? StringView(setting.EmptyText) : "(none)";
				View value = null;
				let text = scope String();
				switch (kind)
				{
				case .Asset:
					let id = *(Guid*)SettingFields.Address(settings, field);
					value = AssetLink(id, emptyText);
					let instance = (id == Guid.Empty) ? null : project.SourceDb.GetInstance(id);
					text.Append((id == Guid.Empty) ? emptyText : (instance != null) ? instance.Name : "(missing)");
				case .AssetList:
					let ids = *(List<Guid>*)SettingFields.Address(settings, field);
					let list = new FlexLayout();
					list.Direction = .Vertical;
					list.AlignItems = .Start;
					for (let id in ids)
					{
						list.AddView(AssetLink(id, "(none)"));
						let instance = project.SourceDb.GetInstance(id);
						if (!text.IsEmpty)
							text.Append(", ");
						text.Append((instance != null) ? instance.Name : "(missing)");
					}
					if (ids.IsEmpty)
					{
						text.Append("(none)");
						list.AddView(Value(text, cDim));
					}
					value = list;
				default:
					SettingText(settings, field, kind, text);
					if (text.IsEmpty)
						continue; // a kind this page does not show
					value = Value(text);
				}
				mRows.Add(new $"{setting.Label}: {text}");
				column.AddView(SettingRow(setting.Label, value));
			}
		}

		let actions = new FlexLayout();
		actions.Padding = .(0, 14, 0, 0);
		actions.AddView(MenuActions("Project/"));
		column.AddView(actions);
		return column;
	}

	/// A label and its value. `value` is consumed.
	private static View SettingRow(StringView label, View value)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.AlignItems = .Start;
		row.Spacing = 10;
		var labelWidth = LayoutStyle();
		labelWidth.Width = SizeSpec.Fixed(Unit.Dp(150.0f));
		labelWidth.Margin = Thickness(0, cLinkInsetY, 0, 0);
		row.AddView(Text(label, 13.0f, cDim), labelWidth);
		// The value at the start of the room left (a link keeps its own width).
		let cell = new FlexLayout();
		cell.Direction = .Vertical;
		cell.AlignItems = .Start;
		cell.AddView(value);
		var grow = LayoutStyle();
		grow.FlexBasis = Unit.Dp(0.0f);
		grow.FlexGrow = 1.0f;
		row.AddView(cell, grow);
		return row;
	}
}
