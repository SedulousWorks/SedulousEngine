using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

// Export Templates (Raptor's editor-gui spec, 5.2, layer 6): the player builds this editor exports
// with, Edit > Export Templates (and Export's own button, over it), a window over its markup
// (Data/Editor/Templates.xml). They are the editor's, not a project's: every project shares them.
// The templates on the left, each by the icon its bundle carries, its name, platform, config and
// engine version, the host build marked as this editor's own and one built for another engine
// warned of; the selected one's details on the right (its id, compiler, engine and whether it is
// this editor's, where it lives, its player, runtime files, symbols, notes; an empty one left out),
// with Reveal and Remove (Delete on the list too), which asks first and cannot take the host build.
// Install from Folder copies a template bundle in; Create from Build makes one from a player build
// folder; with none, it says how to get one. What it needs from outside (the registry, the OS
// folder picker, opening a folder) comes through TemplatesDialogSeams, so a test drives it without
// a window system.

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

/// A template's row (and an export preset's): its icon, its name over its summary, and a warning
/// saying what is wrong when something is (an engine not this editor's, no template here).
class TemplateRow : UIWidget
{
	// Owned by the tree: the row holds its parts and never lets one go.
	private Sedulous.GUI.Image mIcon;
	private Sedulous.GUI.Label mName;
	private Sedulous.GUI.Label mSummary;
	private Sedulous.GUI.Image mWarning;

	public this()
	{
		AddClass("template-row");
		mIcon = Part<Sedulous.GUI.Image>(this, "template-row-icon");
		let text = Part<Panel>(this, "template-row-text");
		mName = Part<Sedulous.GUI.Label>(text, "row-name");
		mSummary = Part<Sedulous.GUI.Label>(text, "template-summary");
		mWarning = Part<Sedulous.GUI.Image>(this, "badge-icon");
		mWarning.AddClass("warning");
		mWarning.Source = "Editor/Icons/warning.svg";
	}

	/// `icon` borrowed (the image takes its own reference; null shows none); `warning` empty:
	/// none.
	public void Show(Sedulous.GUI.Drawable icon, StringView name, StringView summary, StringView warning)
	{
		mIcon.SetDrawable(icon);
		mName.Text = name;
		mSummary.Text = summary;
		mWarning.Tooltip = warning;
		mWarning.Visible = !warning.IsEmpty;
	}

	public bool ShowsWarning => mWarning.Visible;
	public StringView ShownName => mName.Text;
	public StringView ShownSummary => mSummary.Text;

	/// A part of class `cls` in `into`: the tree takes the pointer, not its parts.
	private static T Part<T>(Node into, StringView cls) where T : UIWidget, new
	{
		let part = new T();
		part.AddClass(cls);
		into.AddChild(part);
		part.ReleaseRef(); // the tree's reference keeps it
		return part;
	}
}

class TemplatesDialog
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Templates.xml";
	private const float cWidth = 760.0f;
	private const float cHeight = 460.0f;

	/// A detail's label, its caption and the label showing its value (borrowed from the body).
	private class Detail
	{
		public String Label = new .() ~ delete _;
		public Sedulous.GUI.Label Caption;
		public Sedulous.GUI.Label Value;
	}

	/// The templates as the list's model: a template's id names its row, so the selection stays
	/// on it as the list is read again.
	private class Model : IModel
	{
		private TemplatesDialog mDialog;

		public this(TemplatesDialog dialog) { mDialog = dialog; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mDialog.mRegistry.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			let template = mDialog.TemplateAt(index.Row);
			return ((role == .Display) && (template != null)) ? Sedulous.GUI.Variant(template.Name) : .();
		}

		public override ItemId IdOf(ModelIndex index)
		{
			let template = mDialog.TemplateAt(index.Row);
			return (template != null) ? (ItemId)template.Id.GetHashCode() : NoItem;
		}

		public void Reset() => NotifyReset();
	}

	/// Borrowed.
	private EditorContext mContext;
	private TemplatesDialogSeams mSeams ~ delete _;
	/// A reference of ours (the window holds its own). Declared first: it goes last, after the
	/// model the list it holds borrows.
	private Node mBody = null ~ _?.ReleaseRef();
	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	private Sedulous.GUI.Window mWindow = null ~ _?.ReleaseRef();
	/// BORROWED: what it opened over (its confirms open there too).
	private Node mRoot = null;
	/// Told once when it closes, however it closes. Owned.
	private delegate void() mClosed = null ~ delete _;
	private TemplateRegistry mRegistry = new .() ~ delete _;
	/// One reference each, by template id and folder (a reinstall may carry a new icon).
	private Dictionary<String, Sedulous.GUI.Drawable> mIcons = new .() ~ { ClearIcons(_); delete _; };
	private List<Detail> mDetails = new .() ~ DeleteContainerAndItems!(_);
	/// The question Remove asks, while it is asked (a reference of ours).
	private MessageBox mAsking = null ~ _?.ReleaseRef();
	// The body's: the tree holds them.
	private ListView mList = null;
	private Sedulous.GUI.Button mReveal = null;
	private Sedulous.GUI.Button mRemove = null;
	private uint32 mKeyListener = 0;
	private Model mModel ~ delete _;

	/// The dialog over `body` (the markup's controls by id). Borrows `context`; TAKES OWNERSHIP of
	/// the seams and of a reference to `body`; null makes a dialog that never opens.
	public this(EditorContext context, TemplatesDialogSeams seams, Node body)
	{
		mContext = context;
		mSeams = seams;
		mBody = body;
		mModel = new Model(this);
		if (mBody == null)
			return;
		mWindow = new Sedulous.GUI.Window();
		mWindow.Title = "Export Templates";
		mWindow.AddClass("templates-window");
		mWindow.Size = .(cWidth, cHeight);
		mWindow.Content.AddChild(mBody);
		mList = Find<ListView>("templates-list");
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.Create = new (type) => new TemplateRow();
			rows.Bind = new (row, index) => { BindRow(row, index.Row); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			mList.SetOnSelectionChanged(new (index) => { ShowDetails(); });
			mKeyListener = mList.AddEventListener(.KeyDown, new (e) =>
				{
					let key = (KeyEvent)e;
					if (((KeyCode)key.KeyCode == .Delete) && (key.Modifiers == 0))
					{
						RemoveSelected();
						e.Handled = true;
					}
				});
		}
		BuildDetails();
		mReveal = Find<Sedulous.GUI.Button>("templates-reveal");
		mRemove = Find<Sedulous.GUI.Button>("templates-remove");
		if (mReveal != null)
		{
			mReveal.SetOnClick(new () =>
				{
					let template = Selected;
					if ((template != null) && (mSeams.RevealFolder != null))
						mSeams.RevealFolder(template.Directory);
				});
		}
		if (mRemove != null)
			mRemove.SetOnClick(new () => { RemoveSelected(); });
		if (let install = Find<Sedulous.GUI.Button>("templates-install"))
		{
			install.Tooltip = "Copy in a template bundle (a folder holding a template.xml)";
			install.SetOnClick(new () => { InstallFromFolder(); });
		}
		if (let create = Find<Sedulous.GUI.Button>("templates-create"))
		{
			create.Tooltip = "Make a template from a player build folder (build/<Config>_<Platform>/Sedulous.Engine.Player.Desktop)";
			create.SetOnClick(new () => { CreateFromBuild(); });
		}
		if (let close = Find<Sedulous.GUI.Button>("templates-close"))
			close.SetOnClick(new () => { Close(); });
		// However it closes (Close, its close button, Escape), its owner hears.
		mWindow.SetOnClose(new () =>
			{
				let closed = mClosed;
				mClosed = null;
				if (closed != null)
					closed();
				delete closed;
			});
	}

	/// The body may outlive this: what of it calls back here goes first.
	public ~this()
	{
		if ((mAsking != null) && mAsking.IsOpen)
			mAsking.Close();
		Close();
		if (mList != null)
		{
			mList.RemoveEventListener(mKeyListener);
			mList.Model = null;
			mList.SetRowFactory(null);
		}
	}

	/// Opens it over `root`, the templates read again; `closed` hears when it closes (Export reads
	/// them again). False with no markup or one open. TAKES OWNERSHIP of `closed`, opened or not.
	public bool Open(Node root, delegate void() closed = null)
	{
		if ((mWindow == null) || mWindow.IsOpen)
		{
			delete closed;
			return false;
		}
		mRoot = root;
		delete mClosed;
		mClosed = closed;
		Refresh();
		mWindow.OpenModal(root);
		return true;
	}

	public bool IsOpen => (mWindow != null) && mWindow.IsOpen;

	public void Close()
	{
		if (IsOpen)
			mWindow.Close();
	}

	/// Re-reads the templates, keeping the selected one selected while it is there.
	public void Refresh()
	{
		let selectedId = scope String();
		if (let template = Selected)
			selectedId.Set(template.Id);
		if (mSeams.Refresh != null)
			mSeams.Refresh(mRegistry);
		ClearIcons(mIcons); // a reinstall may carry a new icon
		mModel.Reset();
		int select = 0;
		for (int i < mRegistry.Count)
		{
			if (mRegistry.At(i).Id == selectedId)
				select = i;
		}
		Select(select);
		ShowDetails();
	}

	/// The templates listed, in the registry's order.
	public int TemplateCount => mRegistry.Count;

	/// Borrowed; null out of range.
	public ExportTemplate TemplateAt(int index) => ((index >= 0) && (index < mRegistry.Count)) ? mRegistry.At(index) : null;

	/// The selected template, or null. Borrowed.
	public ExportTemplate Selected => TemplateAt((mList != null) ? mList.SelectedItem : -1);

	public void Select(int index)
	{
		if (mList == null)
			return;
		if ((index >= 0) && (index < mRegistry.Count))
			mList.SelectedItem = (int32)index;
		else
			mList.ClearSelection();
		ShowDetails();
	}

	/// The detail actions, for tests: Remove asks first (RemoveSelected(true) answers).
	public Sedulous.GUI.Button RemoveButton => mRemove;
	public Sedulous.GUI.Button RevealButton => mReveal;

	/// A detail's value by its label ("Engine", "Folder"); empty when it is left out.
	public StringView DetailText(StringView label)
	{
		let detail = DetailFor(label);
		return ((detail != null) && detail.Value.Displayed) ? detail.Value.Text : default;
	}

	/// A detail's value label by its caption (the dialog's); null with none.
	public Sedulous.GUI.Label DetailValue(StringView label)
	{
		let detail = DetailFor(label);
		return (detail != null) ? detail.Value : null;
	}

	/// Whether any of a detail's row shows (its caption or its value); an empty one is left out,
	/// both of them.
	public bool ShowsDetail(StringView label)
	{
		let detail = DetailFor(label);
		return (detail != null) && (detail.Caption.Displayed || detail.Value.Displayed);
	}

	/// Whether a detail's value is marked as a warning (the engine, when not this editor's).
	public bool DetailWarns(StringView label)
	{
		let detail = DetailFor(label);
		return (detail != null) && detail.Value.HasClass("warning");
	}

	/// Whether the state saying there are no templates shows.
	public bool ShowsEmpty
	{
		get
		{
			let empty = Find<UIWidget>("templates-empty");
			return (empty != null) && empty.Displayed;
		}
	}

	/// The window and the list (their controls by id, for a test); null with no markup. The
	/// dialog's and the body's.
	public Sedulous.GUI.Window Window => mWindow;
	public ListView List => mList;

	/// Copies a template bundle in from a folder the user picks, then lists and selects it.
	public void InstallFromFolder()
	{
		PickFolderThen(new (folder) =>
			{
				let id = scope String();
				if (ExportTemplates.Import(folder, Root(.. scope .()), id) case .Ok)
				{
					mContext.Notify(.Success, scope $"Installed template '{id}'.");
					RefreshTo(id);
				}
				else
					mContext.Notify(.Error, "That folder holds no template (no valid template.xml).");
			});
	}

	/// Makes a template from a player build folder the user picks, then lists and selects it.
	public void CreateFromBuild()
	{
		PickFolderThen(new (folder) =>
			{
				let id = scope String();
				if (ExportTemplates.Create(folder, Root(.. scope .()), .Install, id) case .Ok)
				{
					mContext.Notify(.Success, scope $"Created template '{id}'.");
					RefreshTo(id);
				}
				else
					mContext.Notify(.Error, "No player build there: pick a build/<Config>_<Platform>/Sedulous.Engine.Player.Desktop folder.");
			});
	}

	/// Removes the selected template once the user confirms (`confirmed` skips the question); the
	/// host build is never removed.
	public void RemoveSelected(bool confirmed = false)
	{
		let template = Selected;
		if ((template == null) || template.IsHost)
			return;
		if (!confirmed)
		{
			if ((mRoot == null) || ((mAsking != null) && mAsking.IsOpen))
				return; // nothing to ask over, or asking already
			if (mAsking != null)
				mAsking.ReleaseRef();
			let question = new MessageBox();
			mAsking = question;
			question.Configure("Remove Template",
				scope $"Remove '{template.Name}'? Its folder is deleted; presets that pick it fall back to another template for their platform.", .Ok);
			question.ClearButtons();
			question.AddButton("Cancel", "cancel", .Cancel);
			question.AddButton("Remove", "remove", .Destructive);
			let askedId = new String(template.Id);
			question.AddEventListener(.Changed, new [=question, =askedId, =this] (e) =>
				{
					// The one asked about, still the selected one.
					let now = Selected;
					if ((question.ResultName == "remove") && (now != null) && (now.Id == askedId))
						RemoveSelected(true);
				} ~ delete askedId);
			question.OpenModal(mRoot);
			return;
		}
		let id = scope String(template.Id);
		if (ExportTemplates.Remove(Root(.. scope .()), id) case .Ok)
			mContext.Notify(.Success, scope $"Removed template '{id}'.");
		else
			mContext.Notify(.Error, "Removing the template failed (see the Console).");
		Refresh();
	}

	private T Find<T>(StringView id) where T : Node => (mBody != null) ? mBody.FindElement(id) as T : null;

	private static void ClearIcons(Dictionary<String, Sedulous.GUI.Drawable> icons)
	{
		for (let entry in icons)
		{
			delete entry.key;
			entry.value?.ReleaseRef();
		}
		icons.Clear();
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

	/// The icon a template is shown by, made once per template and folder (a reinstall).
	/// Borrowed: the cache holds its reference.
	private Sedulous.GUI.Drawable IconFor(ExportTemplate template)
	{
		let key = scope String();
		key.AppendF("{}|{}", template.Id, template.Directory);
		if (mIcons.TryGetValue(key, let known))
			return known;
		let svg = TemplateIcons.SvgFor(template, .. scope .());
		Sedulous.GUI.Drawable icon = SvgDrawable.FromText(svg);
		mIcons[new String(key)] = icon;
		return icon;
	}

	private void BindRow(Node node, int32 row)
	{
		let shown = node as TemplateRow;
		let template = TemplateAt(row);
		if ((shown == null) || (template == null))
			return;
		shown.Show(IconFor(template), template.Name, SummaryOf(template, .. scope .()),
			ExportTemplates.EngineMatches(template) ? StringView() : "Built for another engine version");
	}

	private void RefreshTo(StringView id)
	{
		Refresh();
		for (int i < mRegistry.Count)
		{
			if (mRegistry.At(i).Id == id)
				Select(i);
		}
	}

	/// Asks the seam for a folder and runs `then` with it, unless the user cancels. CONSUMES
	/// `then`.
	private void PickFolderThen(delegate void(StringView folder) then)
	{
		if (mSeams.PickFolder == null)
		{
			delete then;
			return;
		}
		mSeams.PickFolder(new [=then](folder) =>
			{
				if (!folder.IsEmpty)
					then(folder);
			} ~ delete then);
	}

	private void Root(String outRoot)
	{
		if (mSeams.TemplatesRoot != null)
			mSeams.TemplatesRoot(outRoot);
	}

	// A caption and a value per detail, in the form's two columns.
	private void BuildDetails()
	{
		let fields = Find<UIWidget>("templates-fields");
		if (fields == null)
			return;
		StringView[10] labels = .("Platform", "Config", "Compiler", "Engine", "Source", "Folder", "Player", "Runtime files", "Symbols", "Notes");
		for (let label in labels)
		{
			let caption = new Sedulous.GUI.Label();
			caption.AddClass("form-label");
			caption.Text = label;
			let value = new Sedulous.GUI.Label();
			value.AddClass("template-value");
			fields.AddChild(caption);
			fields.AddChild(value);
			caption.ReleaseRef(); // the tree's references keep them
			value.ReleaseRef();
			let detail = new Detail();
			detail.Label.Set(label);
			detail.Caption = caption;
			detail.Value = value;
			mDetails.Add(detail);
		}
	}

	private Detail DetailFor(StringView label)
	{
		for (let detail in mDetails)
		{
			if (detail.Label == label)
				return detail;
		}
		return null;
	}

	// A detail's value; an empty one leaves its row out.
	private void SetDetail(StringView label, StringView text)
	{
		let detail = DetailFor(label);
		if (detail == null)
			return;
		detail.Value.Text = text;
		detail.Caption.Displayed = !text.IsEmpty;
		detail.Value.Displayed = !text.IsEmpty;
	}

	private void ShowDetails()
	{
		let template = Selected;
		if (let empty = Find<UIWidget>("templates-empty"))
			empty.Displayed = mRegistry.Count == 0;
		if (let detail = Find<UIWidget>("templates-detail"))
			detail.Displayed = template != null;
		if (template == null)
			return;
		if (let icon = Find<Sedulous.GUI.Image>("templates-icon"))
			icon.SetDrawable(IconFor(template));
		if (let name = Find<Sedulous.GUI.Label>("templates-name"))
			name.Text = template.Name;
		if (let id = Find<Sedulous.GUI.Label>("templates-id"))
			id.Text = template.Id;
		SetDetail("Platform", template.Platform);
		SetDetail("Config", template.EffectiveConfig);
		SetDetail("Compiler", template.Compiler);
		let matches = ExportTemplates.EngineMatches(template);
		let engine = scope String(template.EngineVersion.IsEmpty ? "unstamped" : StringView(template.EngineVersion));
		if (!matches)
			engine.AppendF(" (this editor is {}; an export still runs)", EngineVersion.String);
		SetDetail("Engine", engine);
		if (let detail = DetailFor("Engine"))
		{
			if (matches)
				detail.Value.RemoveClass("warning");
			else
				detail.Value.AddClass("warning");
		}
		SetDetail("Source", template.IsHost ? "This editor's own player build (always available)" : "Installed in the templates folder");
		SetDetail("Folder", template.Directory);
		SetDetail("Player", template.PlayerBinary);
		let files = scope String();
		for (let sidecar in template.Sidecars)
		{
			if (!files.IsEmpty)
				files.Append(", ");
			files.Append(sidecar);
		}
		SetDetail("Runtime files", files.IsEmpty ? "none" : StringView(files));
		let symbols = scope String();
		if (template.Symbols.IsEmpty)
			symbols.Set("none");
		else
			symbols.AppendF("{} file(s), staged when a preset asks", template.Symbols.Count);
		SetDetail("Symbols", symbols);
		SetDetail("Notes", template.Notes);
		// The host build is this editor's own, never on disk as a bundle: it cannot be removed.
		if (mRemove != null)
		{
			mRemove.Enabled = !template.IsHost;
			mRemove.Tooltip = template.IsHost ? "This editor's own build cannot be removed" : "Delete this template's folder";
		}
		if (mReveal != null)
			mReveal.Enabled = !template.Directory.IsEmpty;
	}
}
