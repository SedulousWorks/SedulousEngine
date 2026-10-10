using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

/// What the templates dialog asks of the application. Every delegate is owned.
class TemplatesDialogSeams
{
	/// The templates root installs and removals go to (Preferences > Export, or the default).
	public delegate void(String outRoot) TemplatesRoot ~ delete _;
	/// Fills the registry with the templates this host sees (the root's, then the host build).
	public delegate void(TemplateRegistry registry) Refresh ~ delete _;
	/// Asks for a folder. TAKES OWNERSHIP of `chosen` and calls it exactly once: with the
	/// folder, or empty when the user cancels.
	public delegate void(delegate void(StringView folder) chosen) PickFolder ~ delete _;
	/// Shows a folder in the OS file manager.
	public delegate void(StringView folder) RevealFolder ~ delete _;
}

/// The export templates this editor exports with, Edit > Export Templates (and Export's own
/// button, over it). They are the editor's, not a project's: every project shares them. The
/// templates on the left, each by the icon its bundle carries, its name, platform, config and
/// engine version, the host build marked as this editor's own; the selected one's details on
/// the right (its id, compiler, engine version and whether it matches this editor's, where it
/// lives, its player, runtime files, symbols and notes), with Reveal and Remove. Install from
/// Folder copies a template bundle in; Create from Build makes one from a player build
/// directory. The list refreshes in place. What it needs from outside comes through
/// TemplatesDialogSeams, so a test drives it without a window.
class TemplatesDialog : Dialog
{
	private static readonly Color cDimText = .(0.62f, 0.62f, 0.62f, 1.0f);
	private static readonly Color cWarningText = .(0.91f, 0.69f, 0.29f, 1.0f);

	/// A row: the template's icon, its name over its summary, and a warning when its engine is
	/// not this editor's.
	private class Adapter : ListAdapterBase
	{
		private TemplatesDialog mOwner;

		public this(TemplatesDialog owner)
		{
			mOwner = owner;
		}

		public override int32 ItemCount => (int32)mOwner.mRegistry.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 8;
			row.Padding = .(6, 4);
			var centred = LayoutStyle();
			centred.AlignSelf = .Center;
			row.AddView(new DrawableView(null, 26.0f, 26.0f) { KeepAspect = true }, centred);
			let text = new FlexLayout();
			text.Direction = .Vertical;
			text.Spacing = 1;
			let name = new Label();
			name.FontSize.Value = 12.5f;
			text.AddView(name);
			let summary = new Label();
			summary.FontSize.Value = 11.0f;
			summary.TextColor.Value = cDimText;
			text.AddView(summary);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(text, grow);
			let warning = new DrawableView(null, 14.0f, 14.0f);
			warning.TooltipText.Set("Built for another engine version");
			row.AddView(warning, centred);
			return row;
		}

		public override void BindView(View view, int32 position)
		{
			let row = view as FlexLayout;
			let template = mOwner.TemplateAt(position);
			if ((row == null) || (row.ChildCount < 3) || (template == null))
				return;
			(row.GetChildAt(0) as DrawableView).SetDrawable(mOwner.IconFor(template));
			let text = row.GetChildAt(1) as FlexLayout;
			(text.GetChildAt(0) as Label).SetText(template.Name);
			(text.GetChildAt(1) as Label).SetText(SummaryOf(template, .. scope .()));
			let warning = row.GetChildAt(2) as DrawableView;
			let mismatch = !ExportTemplates.EngineMatches(template);
			warning.SetDrawable(mismatch ? Retained(EditorIcons.Warning) : null);
			warning.Visibility = mismatch ? .Visible : .Hidden;
		}
	}

	/// A detail row's key and the label showing its value (borrowed from the content).
	private class Detail
	{
		public String Key = new .() ~ delete _;
		public Label Value;
	}

	private EditorContext mContext;
	private TemplatesDialogSeams mSeams ~ delete _;
	private TemplateRegistry mRegistry = new .() ~ delete _;
	private Adapter mAdapter ~ delete _;
	/// Borrowed: the content owns the views below.
	private ListView mList;
	/// One reference each, by template id and directory (a reinstall may carry a new icon).
	private Dictionary<String, Drawable> mIcons = new .() ~ ClearIcons(_);
	private DrawableView mDetailIcon;
	private Label mDetailName;
	private Label mDetailId;
	private DrawableView mMismatchIcon;
	private Label mEmptyNote;
	private FlexLayout mDetailBody;
	private List<Detail> mDetails = new .() ~ DeleteContainerAndItems!(_);
	private Button mReveal;
	private Button mRemove;

	/// TAKES OWNERSHIP of the seams.
	public this(EditorContext context, TemplatesDialogSeams seams) : base("Export Templates")
	{
		mContext = context;
		mSeams = seams;
		// A fixed size: the details side changes with the selection, the dialog does not.
		MinWidth.Value = 760.0f;
		MaxWidth.Value = 760.0f;
		MinHeight.Value = 460.0f;
		MaxHeight.Value = 460.0f;

		let body = new FlexLayout();
		body.Direction = .Horizontal;
		body.Spacing = 0;

		// The list.
		mAdapter = new Adapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 42.0f;
		mList.Padding = .(4, 4);
		mList.SetAdapter(mAdapter);
		mList.Selection.OnSelectionChanged.Add(new [=this]() => { ShowDetails(); });
		{
			var side = LayoutStyle();
			side.Width = SizeSpec.Fixed(Unit.Dp(290.0f));
			side.Height = SizeSpec.Match();
			body.AddView(mList, side);
		}
		{
			var line = LayoutStyle();
			line.Width = SizeSpec.Fixed(Unit.Dp(1.0f));
			line.Height = SizeSpec.Match();
			body.AddView(new Separator(.Vertical), line);
		}

		// The details.
		let details = new FlexLayout();
		details.Direction = .Vertical;
		details.Spacing = 8;
		details.Padding = .(16, 12);
		BuildDetails(details);
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		{
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			scroll.AddView(details, match);
		}
		{
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Height = SizeSpec.Match();
			body.AddView(scroll, grow);
		}
		SetContent(body);

		let install = AddButton("Install from Folder...", .None);
		install.TooltipText.Set("Copy in a template bundle (a folder holding a template.xml)");
		install.OnClick.Add(new [=this](b) => { InstallFromFolder(); });
		let create = AddButton("Create from Build...", .None);
		create.TooltipText.Set("Make a template from a player build folder (build/<Config>_<Platform>/Sedulous.Engine.Player.Desktop)");
		create.OnClick.Add(new [=this](b) => { CreateFromBuild(); });
		AddButton("Close", .Cancel);

		Refresh();
	}

	public ~this()
	{
		// The list outlives this body (the content holds it); it must not ask a deleted adapter.
		mList.SetAdapter(null);
	}

	private static void ClearIcons(Dictionary<String, Drawable> icons)
	{
		for (let entry in icons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		delete icons;
	}

	/// A shared icon with a reference taken for the view it goes to; null passes through.
	private static Drawable Retained(Drawable icon)
	{
		icon?.AddRef();
		return icon;
	}

	/// "Linux64 · Release · 0.1.0", the line under a template's name.
	private static void SummaryOf(ExportTemplate template, String outText)
	{
		outText.AppendF("{} · {}", template.Platform, template.EffectiveConfig);
		if (!template.EngineVersion.IsEmpty)
			outText.AppendF(" · {}", template.EngineVersion);
		if (template.IsHost)
			outText.Append(" · this editor's own");
	}

	/// The templates listed, in the registry's order.
	public int TemplateCount => mRegistry.Count;

	/// Borrowed; null out of range.
	public ExportTemplate TemplateAt(int index) => ((index >= 0) && (index < mRegistry.Count)) ? mRegistry.At(index) : null;

	/// The selected template, or null. Borrowed.
	public ExportTemplate Selected => TemplateAt(mList.Selection.FirstSelected());

	public void Select(int index)
	{
		if ((index < 0) || (index >= mRegistry.Count))
			return;
		mList.Selection.Select((int32)index);
		mList.ScrollToPosition((int32)index);
	}

	/// The details side's actions, for tests: Remove asks first (RemoveSelected(true) answers).
	public Button RemoveButton => mRemove;
	public Button RevealButton => mReveal;

	/// The detail value shown for a key ("Engine", "Folder"), for tests.
	public StringView DetailText(StringView key)
	{
		for (let detail in mDetails)
		{
			if (detail.Key == key)
				return detail.Value.Text.Value;
		}
		return default;
	}

	/// Re-reads the templates, keeping the selected one selected while it is there.
	public void Refresh()
	{
		let selectedId = scope String();
		if (let template = Selected)
			selectedId.Set(template.Id);
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);
		ClearIconCache(); // a reinstall may carry a new icon
		mList.NotifyDataChanged();
		mList.Selection.ClearSelection();
		var select = 0;
		for (int i < mRegistry.Count)
		{
			if (mRegistry.At(i).Id == selectedId)
				select = i;
		}
		Select(select);
		ShowDetails();
	}

	private void SelectId(StringView id)
	{
		for (int i < mRegistry.Count)
		{
			if (mRegistry.At(i).Id == id)
				Select(i);
		}
	}

	private void ClearIconCache()
	{
		for (let entry in mIcons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		mIcons.Clear();
	}

	/// The icon a template is shown by, made once per template, with a reference taken for the
	/// view it goes to.
	private Drawable IconFor(ExportTemplate template)
	{
		let key = scope String();
		key.AppendF("{}|{}", template.Id, template.Directory);
		if (mIcons.TryGetValue(key, let known))
			return Retained(known);
		let svg = TemplateIcons.SvgFor(template, .. scope .());
		Drawable icon = SVGDrawable.FromString(svg);
		mIcons[new String(key)] = icon;
		return Retained(icon);
	}

	private void BuildDetails(FlexLayout column)
	{
		mEmptyNote = new Label("No templates. Install one from a folder, or create one from a build.");
		mEmptyNote.FontSize.Value = 12.0f;
		mEmptyNote.WordWrap.Value = true;
		mEmptyNote.TextColor.Value = cDimText;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mEmptyNote, match);

		mDetailBody = new FlexLayout();
		mDetailBody.Direction = .Vertical;
		mDetailBody.Spacing = 6;
		column.AddView(mDetailBody, match);

		// The heading: the icon large, the name over the id.
		{
			let heading = new FlexLayout();
			heading.Direction = .Horizontal;
			heading.Spacing = 12;
			var centred = LayoutStyle();
			centred.AlignSelf = .Center;
			mDetailIcon = new DrawableView(null, 44.0f, 44.0f) { KeepAspect = true };
			heading.AddView(mDetailIcon, centred);
			let names = new FlexLayout();
			names.Direction = .Vertical;
			names.Spacing = 2;
			mDetailName = new Label();
			mDetailName.FontSize.Value = 16.0f;
			names.AddView(mDetailName);
			mDetailId = new Label();
			mDetailId.FontSize.Value = 11.0f;
			mDetailId.TextColor.Value = cDimText;
			names.AddView(mDetailId);
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			heading.AddView(names, grow);
			mDetailBody.AddView(heading);
		}
		{
			var line = LayoutStyle();
			line.Width = SizeSpec.Match();
			line.Height = SizeSpec.Fixed(Unit.Dp(1.0f));
			mDetailBody.AddView(new Separator(), line);
		}

		AddDetail("Platform");
		AddDetail("Config");
		AddDetail("Compiler");
		{
			let engine = AddDetail("Engine");
			// The warning sits after the version when the template was built for another.
			let row = engine.Parent as FlexLayout;
			mMismatchIcon = new DrawableView(Retained(EditorIcons.Warning), 14.0f, 14.0f);
			var centred = LayoutStyle();
			centred.AlignSelf = .Center;
			row.InsertView(mMismatchIcon, 1, centred);
		}
		AddDetail("Source");
		AddDetail("Folder");
		AddDetail("Player");
		AddDetail("Runtime files");
		AddDetail("Symbols");
		AddDetail("Notes");

		// Its actions.
		let actions = new FlexLayout();
		actions.Direction = .Horizontal;
		actions.Spacing = 8;
		mReveal = new Button("Reveal Folder");
		mReveal.OnClick.Add(new [=this](b) =>
			{
				let template = Selected;
				if ((template != null) && (mSeams.RevealFolder != null))
					mSeams.RevealFolder(template.Directory);
			});
		actions.AddView(mReveal);
		mRemove = new Button("Remove...");
		mRemove.OnClick.Add(new [=this](b) => { RemoveSelected(); });
		actions.AddView(mRemove);
		var top = LayoutStyle();
		top.Margin = Thickness(0, 6, 0, 0);
		mDetailBody.AddView(actions, top);
	}

	private Label AddDetail(StringView key)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8;
		let keyLabel = new Label(key);
		keyLabel.FontSize.Value = 12.0f;
		keyLabel.TextColor.Value = cDimText;
		var keyWidth = LayoutStyle();
		keyWidth.Width = SizeSpec.Fixed(Unit.Dp(96.0f));
		row.AddView(keyLabel, keyWidth);
		let value = new Label();
		value.FontSize.Value = 12.0f;
		value.WordWrap.Value = true;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(value, grow);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		mDetailBody.AddView(row, match);
		let detail = new Detail();
		detail.Key.Set(key);
		detail.Value = value;
		mDetails.Add(detail);
		return value;
	}

	private Detail DetailFor(StringView key)
	{
		for (let detail in mDetails)
		{
			if (detail.Key == key)
				return detail;
		}
		return null;
	}

	private void SetDetail(StringView key, StringView text)
	{
		let detail = DetailFor(key);
		if (detail == null)
			return;
		detail.Value.SetText(text.IsEmpty ? "-" : text);
		// A row with nothing to say (no compiler, no notes) folds away.
		let folds = text.IsEmpty && ((key == "Notes") || (key == "Compiler"));
		detail.Value.Parent.Visibility = folds ? .Gone : .Visible;
	}

	private void ShowDetails()
	{
		let template = Selected;
		mEmptyNote.Visibility = (template == null) ? .Visible : .Gone;
		mDetailBody.Visibility = (template == null) ? .Gone : .Visible;
		if (template == null)
			return;
		mDetailIcon.SetDrawable(IconFor(template));
		mDetailName.SetText(template.Name);
		mDetailId.SetText(template.Id);
		SetDetail("Platform", template.Platform);
		SetDetail("Config", template.EffectiveConfig);
		SetDetail("Compiler", template.Compiler);
		let matches = ExportTemplates.EngineMatches(template);
		{
			let engine = scope String(template.EngineVersion.IsEmpty ? "unstamped" : StringView(template.EngineVersion));
			if (!matches)
				engine.AppendF(" (this editor is {}; an export still runs)", EngineVersion.String);
			SetDetail("Engine", engine);
			DetailFor("Engine").Value.TextColor.Value = matches ? (Color?)null : cWarningText;
			mMismatchIcon.Visibility = matches ? .Gone : .Visible;
		}
		SetDetail("Source", template.IsHost ? "This editor's own player build (always available)" : "Installed in the templates folder");
		SetDetail("Folder", template.Directory);
		SetDetail("Player", template.PlayerBinary);
		{
			let files = scope String();
			for (let sidecar in template.Sidecars)
			{
				if (!files.IsEmpty)
					files.Append(", ");
				files.Append(sidecar);
			}
			SetDetail("Runtime files", files.IsEmpty ? "none" : StringView(files));
		}
		SetDetail("Symbols", template.Symbols.IsEmpty ? "none" : scope $"{template.Symbols.Count} file(s), staged when a preset asks");
		SetDetail("Notes", template.Notes);
		// The host build is this editor's own, never on disk as a bundle: it cannot be removed.
		mRemove.IsEnabled = !template.IsHost;
		mRemove.TooltipText.Set(template.IsHost ? "This editor's own build cannot be removed" : "Delete this template's folder");
		mReveal.IsEnabled = !template.Directory.IsEmpty;
		Invalidate();
	}

	/// Copies a template bundle in from a folder the user picks, then lists and selects it.
	public void InstallFromFolder()
	{
		PickFolderThen(new [=this](folder) =>
			{
				let id = scope String();
				if (ExportTemplates.Import(folder, Root(.. scope .()), id) case .Ok)
				{
					mContext.Notify(.Success, scope $"Installed template '{id}'.");
					Refresh();
					SelectId(id);
				}
				else
					mContext.Notify(.Error, "That folder holds no template (no valid template.xml).");
			});
	}

	/// Makes a template from a player build folder the user picks, then lists and selects it.
	public void CreateFromBuild()
	{
		PickFolderThen(new [=this](folder) =>
			{
				let id = scope String();
				if (ExportTemplates.Create(folder, Root(.. scope .()), .Install, id) case .Ok)
				{
					mContext.Notify(.Success, scope $"Created template '{id}'.");
					Refresh();
					SelectId(id);
				}
				else
					mContext.Notify(.Error, "No player build there: pick a build/<Config>_<Platform>/Sedulous.Engine.Player.Desktop folder.");
			});
	}

	/// Asks the seam for a folder and runs `then` with it, unless the user cancels. The dialog
	/// holds a reference across the pick, which the OS may answer after it has closed.
	/// CONSUMES `then`.
	private void PickFolderThen(delegate void(StringView folder) then)
	{
		if (mSeams.PickFolder == null)
		{
			delete then;
			return;
		}
		AddRef();
		mSeams.PickFolder(new [=this, =then](folder) =>
			{
				if (!folder.IsEmpty)
					then(folder);
				delete then;
				ReleaseRef();
			});
	}

	private void Root(String outRoot)
	{
		if (mSeams.TemplatesRoot != null)
			mSeams.TemplatesRoot(outRoot);
	}

	/// Removes the selected template once the user confirms (`confirmed` skips the question).
	public void RemoveSelected(bool confirmed = false)
	{
		let template = Selected;
		if ((template == null) || template.IsHost)
			return;
		if (!confirmed)
		{
			if (Context == null)
				return;
			let confirm = new ConfirmDialog("Remove Template",
				scope $"Remove '{template.Name}'? Its folder is deleted; presets that pick it fall back to another template for their platform.",
				scope StringView[]("Remove", "Cancel"));
			confirm.OnChosen = new [=this](choice) =>
				{
					if (choice == 0)
						RemoveSelected(true);
				};
			confirm.Show(Context);
			return;
		}
		let id = scope String(template.Id);
		if (ExportTemplates.Remove(Root(.. scope .()), id) case .Ok)
			mContext.Notify(.Success, scope $"Removed template '{id}'.");
		else
			mContext.Notify(.Error, "Removing the template failed (see the Console).");
		Refresh();
	}
}
